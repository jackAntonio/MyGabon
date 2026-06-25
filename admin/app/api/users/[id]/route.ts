import { NextRequest, NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase'
import { requirePermission } from '@/lib/apiAuth'

interface RouteParams {
  params: Promise<{
    id: string
  }>
}

// Champs qu'un admin est autorisé à modifier via cette route. wallet_balance
// est volontairement exclu : tout crédit/débit doit passer par le workflow
// wallet_adjustments (avec approbation et piste d'audit), jamais par un
// update() direct qui écraserait le solde sans trace ni double contrôle.
// email/id/total_orders/created_at/updated_at sont également exclus.
const UPDATABLE_USER_FIELDS = ['full_name', 'phone_number', 'avatar_url', 'status'] as const

export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    const { response } = await requirePermission('users:read')
    if (response) return response

    const { id } = await params
    const { data, error } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('id', id)
      .single()

    if (error) throw error
    if (!data) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('GET /api/users/[id] error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function PUT(request: NextRequest, { params }: RouteParams) {
  try {
    const { session, response } = await requirePermission('users:update')
    if (response) return response

    const { id } = await params
    const body = await request.json()

    // Liste blanche : seuls les champs de UPDATABLE_USER_FIELDS sont retenus,
    // tout le reste du body (wallet_balance, email, id, role...) est ignoré.
    // Avant ce filtre, body était passé tel quel à .update(), ce qui, combiné
    // à la clé service_role qui contourne RLS et les GRANT colonne, permettait
    // à n'importe quel admin de modifier n'importe quel champ d'un user.
    const updates: Record<string, unknown> = {}
    for (const field of UPDATABLE_USER_FIELDS) {
      if (field in body) updates[field] = body[field]
    }

    if (Object.keys(updates).length === 0) {
      return NextResponse.json({ error: 'No valid fields to update' }, { status: 400 })
    }

    // Get current user to track changes
    const { data: currentData } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('id', id)
      .single()

    // Update user
    const { data, error } = await supabaseAdmin
      .from('users')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (error) throw error
    if (!data) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    // Log audit
    const changes = Object.keys(updates).reduce((acc: any, key) => {
      if (currentData?.[key] !== updates[key]) {
        acc[key] = { from: currentData?.[key], to: updates[key] }
      }
      return acc
    }, {})

    await supabaseAdmin.from('admin_audit_logs').insert({
      admin_id: (session!.user as any).id,
      action: 'user_updated',
      resource_type: 'users',
      resource_id: id,
      changes,
    })

    return NextResponse.json(data)
  } catch (error) {
    console.error('PUT /api/users/[id] error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function DELETE(request: NextRequest, { params }: RouteParams) {
  try {
    const { session, response } = await requirePermission('users:delete')
    if (response) return response

    const { id } = await params

    // Soft delete (set status to 'deleted')
    const { data, error } = await supabaseAdmin
      .from('users')
      .update({ status: 'deleted' })
      .eq('id', id)
      .select()
      .single()

    if (error) throw error
    if (!data) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    // Log audit
    await supabaseAdmin.from('admin_audit_logs').insert({
      admin_id: (session!.user as any).id,
      action: 'user_deleted',
      resource_type: 'users',
      resource_id: id,
    })

    return NextResponse.json({ message: 'User deleted successfully' })
  } catch (error) {
    console.error('DELETE /api/users/[id] error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
