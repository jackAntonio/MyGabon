import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth/next'
import { authOptions } from '@/app/api/auth/[...nextauth]'
import { supabaseAdmin } from '@/lib/supabase'

interface RouteParams {
  params: {
    id: string
  }
}

export async function POST(request: NextRequest, { params }: RouteParams) {
  try {
    const session = await getServerSession(authOptions)
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

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
        reviewed_by: (session.user as any).id,
        reviewed_at: new Date().toISOString(),
        notes,
      })
      .eq('id', params.id)
      .select()
      .single()

    if (error) throw error
    if (!data) {
      return NextResponse.json({ error: 'Image not found' }, { status: 404 })
    }

    // Log audit
    await supabaseAdmin.from('admin_audit_logs').insert({
      admin_id: (session.user as any).id,
      action: 'image_rejected',
      resource_type: 'image_moderation',
      resource_id: params.id,
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
