import { NextRequest, NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase'
import { requirePermission } from '@/lib/apiAuth'

interface RouteParams {
  params: Promise<{
    id: string
  }>
}

// Champs réellement modifiables sur `users` via cette route. Le solde
// (user_wallets) est volontairement exclu : tout crédit/débit doit passer
// par un workflow tracé, jamais par un update() direct.
const UPDATABLE_USER_FIELDS = ['full_name', 'phone_number', 'avatar_url'] as const

function deriveStatus(blocked: boolean): 'active' | 'suspended' {
  return blocked ? 'suspended' : 'active'
}

export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    const { response } = await requirePermission('users:read')
    if (response) return response

    const { id } = await params
    const { data, error } = await supabaseAdmin.from('users').select('*').eq('id', id).single()
    if (error) throw error
    if (!data) return NextResponse.json({ error: 'User not found' }, { status: 404 })

    // Enrichissement solde + nb de commandes (cf. /api/users).
    const [{ data: wallet }, { count: orders }] = await Promise.all([
      supabaseAdmin.from('user_wallets').select('balance').eq('user_id', id).maybeSingle(),
      supabaseAdmin
        .from('transactions')
        .select('*', { count: 'exact', head: true })
        .eq('buyer_id', id),
    ])

    return NextResponse.json({
      ...data,
      status: deriveStatus(data.blocked as boolean),
      wallet_balance: Number(wallet?.balance) || 0,
      total_orders: orders || 0,
    })
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

    // Liste blanche des champs texte + traduction du `status` de l'UI vers la
    // colonne réelle `blocked` (suspended <-> blocked=true).
    const updates: Record<string, unknown> = {}
    for (const field of UPDATABLE_USER_FIELDS) {
      if (field in body) updates[field] = body[field]
    }
    if ('status' in body) {
      updates.blocked = body.status === 'suspended'
      updates.blocked_reason = body.status === 'suspended' ? body.reason || 'Suspendu par un admin' : null
      updates.blocked_at = body.status === 'suspended' ? new Date().toISOString() : null
    }

    if (Object.keys(updates).length === 0) {
      return NextResponse.json({ error: 'No valid fields to update' }, { status: 400 })
    }

    const { data: currentData } = await supabaseAdmin.from('users').select('*').eq('id', id).single()

    const { data, error } = await supabaseAdmin
      .from('users')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    if (!data) return NextResponse.json({ error: 'User not found' }, { status: 404 })

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

    return NextResponse.json({ ...data, status: deriveStatus(data.blocked as boolean) })
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

    // Pas de suppression dure ni de colonne 'deleted' dans le schéma actif :
    // on suspend (blocked=true), réversible depuis la fiche utilisateur.
    const { data, error } = await supabaseAdmin
      .from('users')
      .update({
        blocked: true,
        blocked_reason: 'Suspendu par un admin',
        blocked_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    if (!data) return NextResponse.json({ error: 'User not found' }, { status: 404 })

    await supabaseAdmin.from('admin_audit_logs').insert({
      admin_id: (session!.user as any).id,
      action: 'user_suspended',
      resource_type: 'users',
      resource_id: id,
    })

    return NextResponse.json({ message: 'Utilisateur suspendu' })
  } catch (error) {
    console.error('DELETE /api/users/[id] error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
