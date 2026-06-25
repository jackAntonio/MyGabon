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
    const { session, response } = await requirePermission('images:reject')
    if (response) return response

    const { id } = await params
    const body = await request.json()
    const { reason, notes } = body

    if (!reason) {
      return NextResponse.json({ error: 'Reason is required' }, { status: 400 })
    }

    // Update image status
    const { data, error } = await supabaseAdmin
      .from('image_moderation')
      .update({
        status: 'rejected',
        reason_rejected: reason,
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
      action: 'image_rejected',
      resource_type: 'image_moderation',
      resource_id: id,
      changes: {
        status: { from: 'pending', to: 'rejected' },
        reason,
        notes,
      },
    })

    return NextResponse.json(data)
  } catch (error) {
    console.error('POST /api/images/[id]/reject error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
