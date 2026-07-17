import { NextRequest, NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase'
import { requirePermission } from '@/lib/apiAuth'

// Vue portefeuille réelle : soldes agrégés + dernières transactions du
// marketplace (schéma actif), en remplacement des données mockées.

const PAYMENT_LABELS: Record<string, string> = {
  mygabon_wallet: 'MyGabon Wallet',
  airtel_money: 'Airtel Money',
  moov_money: 'Moov Money',
  apple_pay: 'Apple Pay',
  google_pay: 'Google Pay',
  cash: 'Espèces',
  cash_on_delivery: 'Paiement à la livraison',
}

export async function GET(request: NextRequest) {
  try {
    const { response } = await requirePermission('wallet:read')
    if (response) return response

    const { searchParams } = new URL(request.url)
    const parsedPage = parseInt(searchParams.get('page') || '1')
    const page = Number.isNaN(parsedPage) || parsedPage < 1 ? 1 : parsedPage
    const filter = searchParams.get('filter') || 'all'
    const limit = 20
    const offset = (page - 1) * limit
    const num = (v: unknown) => Number(v) || 0

    // ── Stats agrégées ──────────────────────────────────────────
    // Volume total en circulation = somme des soldes wallet.
    const { data: wallets } = await supabaseAdmin.from('user_wallets').select('balance')
    const totalBalance = (wallets || []).reduce((s, w) => s + num(w.balance), 0)

    // Toutes les transactions réussies : frais collectés + compte.
    const { data: successTx } = await supabaseAdmin
      .from('transactions')
      .select('actual_fee, delivery_fee, driver_payout')
      .eq('status', 'success')
    const feesCollected = (successTx || []).reduce(
      (s, t) => s + num(t.actual_fee) + (num(t.delivery_fee) - num(t.driver_payout)),
      0
    )
    const successCount = (successTx || []).length

    // En attente : COD pas encore encaissé.
    const { data: pendingTx } = await supabaseAdmin
      .from('transactions')
      .select('gross_amount, visible_fee, delivery_fee')
      .eq('payment_method', 'cash_on_delivery')
      .eq('status', 'pending')
    const pendingAmount = (pendingTx || []).reduce(
      (s, t) => s + num(t.gross_amount) + num(t.visible_fee) + num(t.delivery_fee),
      0
    )

    // ── Transactions paginées ───────────────────────────────────
    let query = supabaseAdmin
      .from('transactions')
      .select('id, buyer_id, gross_amount, visible_fee, delivery_fee, payment_method, status, created_at', {
        count: 'exact',
      })
    if (['success', 'pending', 'failed'].includes(filter)) {
      query = query.eq('status', filter)
    }
    const { data: txRows, count, error } = await query
      .range(offset, offset + limit - 1)
      .order('created_at', { ascending: false })
    if (error) throw error

    // Noms des acheteurs (profils publics) attachés.
    const buyerIds = [...new Set((txRows || []).map((t) => t.buyer_id as string))]
    const { data: profiles } = buyerIds.length
      ? await supabaseAdmin.from('profiles_public').select('id, full_name').in('id', buyerIds)
      : { data: [] as { id: string; full_name: string }[] }
    const nameById = new Map((profiles || []).map((p) => [p.id as string, p.full_name as string]))

    const transactions = (txRows || []).map((t) => ({
      id: t.id,
      user: nameById.get(t.buyer_id as string) || 'Utilisateur',
      amount: num(t.gross_amount) + num(t.visible_fee) + num(t.delivery_fee),
      method: PAYMENT_LABELS[t.payment_method as string] || t.payment_method,
      status: t.status,
      date: t.created_at,
    }))

    return NextResponse.json({
      stats: {
        totalBalance: Math.round(totalBalance),
        successCount,
        pendingAmount: Math.round(pendingAmount),
        feesCollected: Math.round(feesCollected),
      },
      transactions,
      pagination: {
        page,
        limit,
        total: count || 0,
        pages: Math.ceil((count || 0) / limit),
      },
    })
  } catch (error) {
    console.error('GET /api/wallet error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
