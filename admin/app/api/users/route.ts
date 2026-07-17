import { NextRequest, NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase'
import { requirePermission } from '@/lib/apiAuth'

// Le schéma actif de `users` n'a ni `status`, ni `wallet_balance`, ni
// `total_orders` : on les SYNTHÉTISE pour l'UI du dashboard.
//   status        <- dérivé de `blocked` (true => 'suspended', sinon 'active')
//   wallet_balance <- table `user_wallets`
//   total_orders   <- nb de transactions où l'utilisateur est acheteur
// Aucune colonne n'est ajoutée à `users` : le dashboard s'adapte au schéma
// de l'app, jamais l'inverse.

function deriveStatus(blocked: boolean): 'active' | 'suspended' {
  return blocked ? 'suspended' : 'active'
}

export async function GET(request: NextRequest) {
  try {
    const { response } = await requirePermission('users:read')
    if (response) return response

    const { searchParams } = new URL(request.url)
    const parsedPage = parseInt(searchParams.get('page') || '1')
    const page = Number.isNaN(parsedPage) || parsedPage < 1 ? 1 : parsedPage
    const search = searchParams.get('search') || ''
    const status = searchParams.get('status') || ''
    const limit = 20
    const offset = (page - 1) * limit

    let query = supabaseAdmin.from('users').select('*', { count: 'exact' })

    // Le filtre de statut de l'UI se traduit sur la colonne réelle `blocked`.
    // 'inactive'/'deleted' n'ont pas d'équivalent : on ne filtre alors sur rien
    // (aucun résultat pour 'deleted' n'aurait de sens, on renvoie tout).
    if (status === 'suspended') query = query.eq('blocked', true)
    else if (status === 'active') query = query.eq('blocked', false)

    if (search) {
      const safeSearch = search.replace(/[,()%*]/g, '')
      query = query.or(`email.ilike.%${safeSearch}%,full_name.ilike.%${safeSearch}%`)
    }

    query = query.range(offset, offset + limit - 1).order('created_at', { ascending: false })

    const { data, error, count } = await query
    if (error) throw error

    // Enrichissement solde + nb de commandes pour la page courante uniquement.
    const ids = (data || []).map((u) => u.id as string)
    const [wallets, orderCounts] = await Promise.all([
      ids.length
        ? supabaseAdmin.from('user_wallets').select('user_id, balance').in('user_id', ids)
        : Promise.resolve({ data: [] as { user_id: string; balance: number }[] }),
      ids.length
        ? supabaseAdmin.from('transactions').select('buyer_id').in('buyer_id', ids)
        : Promise.resolve({ data: [] as { buyer_id: string }[] }),
    ])
    const balanceById = new Map(
      (wallets.data || []).map((w) => [w.user_id as string, Number(w.balance) || 0])
    )
    const ordersById = new Map<string, number>()
    for (const t of orderCounts.data || []) {
      ordersById.set(t.buyer_id as string, (ordersById.get(t.buyer_id as string) || 0) + 1)
    }

    const enriched = (data || []).map((u) => ({
      ...u,
      status: deriveStatus(u.blocked as boolean),
      wallet_balance: balanceById.get(u.id as string) || 0,
      total_orders: ordersById.get(u.id as string) || 0,
    }))

    return NextResponse.json({
      data: enriched,
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
    const { email, full_name } = body
    if (!email || !full_name) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
    }

    // NB : crée une ligne dans public.users mais PAS de compte auth.users —
    // l'utilisateur ne pourra pas se connecter tant qu'il ne s'inscrit pas
    // lui-même via l'app. Utile surtout pour du pré-enregistrement/import.
    const { data, error } = await supabaseAdmin
      .from('users')
      .insert({ email, full_name })
      .select()
      .single()
    if (error) throw error

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
