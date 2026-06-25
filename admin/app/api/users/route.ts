import { NextRequest, NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase'
import { requirePermission } from '@/lib/apiAuth'

export async function GET(request: NextRequest) {
  try {
    const { response } = await requirePermission('users:read')
    if (response) return response

    // Get pagination and filters
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get('page') || '1')
    const search = searchParams.get('search') || ''
    const status = searchParams.get('status') || ''
    const limit = 20
    const offset = (page - 1) * limit

    // Build query
    let query = supabaseAdmin.from('users').select('*', { count: 'exact' })

    // Apply filters
    if (status) {
      query = query.eq('status', status)
    }

    if (search) {
      // Échappe les caractères spéciaux du filtre PostgREST (, ( ) *) pour
      // empêcher l'injection de conditions OR/AND supplémentaires via le
      // paramètre de recherche.
      const safeSearch = search.replace(/[,()%*]/g, '')
      query = query.or(`email.ilike.%${safeSearch}%,full_name.ilike.%${safeSearch}%`)
    }

    // Apply pagination
    query = query.range(offset, offset + limit - 1).order('created_at', { ascending: false })

    const { data, error, count } = await query

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
    console.error('GET /api/users error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const { session, response } = await requirePermission('users:create')
    if (response) return response

    const body = await request.json()
    const { email, full_name, status } = body

    // Validate input
    if (!email || !full_name) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
    }

    // Create user
    const { data, error } = await supabaseAdmin
      .from('users')
      .insert({
        email,
        full_name,
        status: status || 'active',
      })
      .select()
      .single()

    if (error) throw error

    // Log audit
    await supabaseAdmin.from('admin_audit_logs').insert({
      admin_id: (session!.user as any).id,
      action: 'user_created',
      resource_type: 'users',
      resource_id: data.id,
    })

    return NextResponse.json(data)
  } catch (error) {
    console.error('POST /api/users error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
