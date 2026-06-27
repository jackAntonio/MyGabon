import { NextRequest, NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase'
import { requirePermission } from '@/lib/apiAuth'

export async function GET(request: NextRequest) {
  try {
    const { response } = await requirePermission('images:read')
    if (response) return response

    const { searchParams } = new URL(request.url)
    const parsedPage = parseInt(searchParams.get('page') || '1')
    const page = Number.isNaN(parsedPage) || parsedPage < 1 ? 1 : parsedPage
    const status = searchParams.get('status') || 'pending'
    const limit = 20
    const offset = (page - 1) * limit

    const { data, error, count } = await supabaseAdmin
      .from('image_moderation')
      .select('*', { count: 'exact' })
      .eq('status', status)
      .range(offset, offset + limit - 1)
      .order('created_at', { ascending: false })

    if (error) throw error

    return NextResponse.json({
      data,
      pagination: {
        page,
        limit,
        total: count || 0,
        pages: Math.ceil((count || 0) / limit),
      },
    })
  } catch (error) {
    console.error('GET /api/images error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
