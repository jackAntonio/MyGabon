import { NextRequest, NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase'
import { requirePermission } from '@/lib/apiAuth'

interface RouteParams {
  params: Promise<{
    id: string
  }>
}

export async function POST(request: NextRequest, { params }: RouteParams) {
  try {
    const { session, response } = await requirePermission('images:approve')
    if (response) return response

    const { id } = await params
    const body = await request.json()
    const { notes } = body

    // Update image status
    const { data, error } = await supabaseAdmin
      .from('image_moderation')
      .update({
        status: 'approved',
        reviewed_by: (session!.user as any).id,
        reviewed_at: new Date().toISOString(),
        notes,
      })
      .eq('id', id)
      .select()
      .single()

    if (error) throw error
    if (!data) {
      return NextResponse.json({ error: 'Image not found' }, { status: 404 })
    }

    // Log audit
    await supabaseAdmin.from('admin_audit_logs').insert({
      admin_id: (session!.user as any).id,
      action: 'image_approved',
      resource_type: 'image_moderation',
      resource_id: id,
      changes: {
        status: { from: 'pending', to: 'approved' },
        notes,
      },
    })

    return NextResponse.json(data)
  } catch (error) {
    console.error('POST /api/images/[id]/approve error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
