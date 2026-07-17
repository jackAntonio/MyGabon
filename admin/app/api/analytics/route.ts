import { NextRequest, NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase'
import { requirePermission } from '@/lib/apiAuth'

// Statistiques réelles de l'app, calculées à partir du schéma actif
// (transactions / products / users / user_wallets). Remplace les données
// mockées de la page Analytiques.
//
// Agrégation faite en JS après lecture bornée par la fenêtre de dates :
// la marketplace est à un stade où le volume le permet, et ça évite de
// multiplier les fonctions SQL. Si le volume explose, basculer ces calculs
// vers des fonctions Postgres (SECURITY DEFINER) appelées en RPC.

type Range = '7days' | '30days' | '90days' | 'year'

const RANGE_DAYS: Record<Range, number> = {
  '7days': 7,
  '30days': 30,
  '90days': 90,
  year: 365,
}

// Plafond de sécurité sur le nombre de transactions relues (garde-fou mémoire).
const MAX_ROWS = 20000

function bucketKey(d: Date, granularity: 'day' | 'week' | 'month'): string {
  const y = d.getUTCFullYear()
  const m = String(d.getUTCMonth() + 1).padStart(2, '0')
  const day = String(d.getUTCDate()).padStart(2, '0')
  if (granularity === 'month') return `${y}-${m}`
  if (granularity === 'week') {
    // Lundi de la semaine ISO comme clé.
    const tmp = new Date(Date.UTC(y, d.getUTCMonth(), d.getUTCDate()))
    const dow = (tmp.getUTCDay() + 6) % 7 // 0 = lundi
    tmp.setUTCDate(tmp.getUTCDate() - dow)
    return `${tmp.getUTCFullYear()}-${String(tmp.getUTCMonth() + 1).padStart(2, '0')}-${String(tmp.getUTCDate()).padStart(2, '0')}`
  }
  return `${y}-${m}-${day}`
}

function bucketLabel(key: string, granularity: 'day' | 'week' | 'month'): string {
  if (granularity === 'month') {
    const [y, m] = key.split('-')
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc']
    return `${months[parseInt(m) - 1]} ${y.slice(2)}`
  }
  const [, m, d] = key.split('-')
  return `${d}/${m}`
}

export async function GET(request: NextRequest) {
  try {
    const { response } = await requirePermission('analytics:read')
    if (response) return response

    const { searchParams } = new URL(request.url)
    const range = (searchParams.get('range') as Range) || '7days'
    const days = RANGE_DAYS[range] ?? 7
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000)
    const sinceIso = since.toISOString()

    const granularity: 'day' | 'week' | 'month' =
      days <= 31 ? 'day' : days <= 120 ? 'week' : 'month'

    // ── Compteurs utilisateurs ──────────────────────────────────
    const [{ count: usersTotal }, { count: newUsers }, { count: activeUsers }] =
      await Promise.all([
        supabaseAdmin.from('users').select('*', { count: 'exact', head: true }),
        supabaseAdmin
          .from('users')
          .select('*', { count: 'exact', head: true })
          .gte('created_at', sinceIso),
        supabaseAdmin
          .from('users')
          .select('*', { count: 'exact', head: true })
          .gte('last_login_at', sinceIso),
      ])

    // ── Transactions de la fenêtre ──────────────────────────────
    const { data: txns, error: txErr } = await supabaseAdmin
      .from('transactions')
      .select(
        'id, product_id, gross_amount, visible_fee, actual_fee, delivery_fee, driver_payout, payment_method, status, delivery_status, created_at'
      )
      .gte('created_at', sinceIso)
      .order('created_at', { ascending: true })
      .limit(MAX_ROWS)

    if (txErr) throw txErr
    const rows = txns || []
    const success = rows.filter((t) => t.status === 'success')

    // GMV = valeur brute des ventes réussies ; commission = ce que la
    // plateforme garde réellement (5% + marge de livraison retenue).
    const num = (v: unknown) => Number(v) || 0
    const gmv = success.reduce((s, t) => s + num(t.gross_amount), 0)
    const commission = success.reduce(
      (s, t) => s + num(t.actual_fee) + (num(t.delivery_fee) - num(t.driver_payout)),
      0
    )
    const productsSold = success.length
    const avgBasket = productsSold > 0 ? gmv / productsSold : 0

    // En attente de règlement : commandes COD pas encore encaissées.
    const pendingAmount = rows
      .filter((t) => t.payment_method === 'cash_on_delivery' && t.status === 'pending')
      .reduce((s, t) => s + num(t.gross_amount) + num(t.visible_fee) + num(t.delivery_fee), 0)

    // ── Série temporelle : ventes + revenus par bucket ──────────
    const salesBucket = new Map<string, { orders: number; revenue: number }>()
    for (const t of success) {
      const key = bucketKey(new Date(t.created_at as string), granularity)
      const cur = salesBucket.get(key) || { orders: 0, revenue: 0 }
      cur.orders += 1
      cur.revenue += num(t.actual_fee) + (num(t.delivery_fee) - num(t.driver_payout))
      salesBucket.set(key, cur)
    }

    // ── Série temporelle : inscriptions par bucket ──────────────
    const { data: userRows } = await supabaseAdmin
      .from('users')
      .select('created_at')
      .gte('created_at', sinceIso)
      .limit(MAX_ROWS)
    const signupBucket = new Map<string, number>()
    for (const u of userRows || []) {
      const key = bucketKey(new Date(u.created_at as string), granularity)
      signupBucket.set(key, (signupBucket.get(key) || 0) + 1)
    }

    // Buckets ordonnés couvrant toute la fenêtre (même vides).
    const timeseries: {
      label: string
      orders: number
      revenue: number
      signups: number
    }[] = []
    const seen = new Set<string>()
    const step = granularity === 'month' ? 28 : granularity === 'week' ? 7 : 1
    for (let d = new Date(since); d <= new Date(); d.setUTCDate(d.getUTCDate() + step)) {
      const key = bucketKey(d, granularity)
      if (seen.has(key)) continue
      seen.add(key)
      const s = salesBucket.get(key) || { orders: 0, revenue: 0 }
      timeseries.push({
        label: bucketLabel(key, granularity),
        orders: s.orders,
        revenue: Math.round(s.revenue),
        signups: signupBucket.get(key) || 0,
      })
    }

    // ── Ventes par catégorie & top produits ─────────────────────
    const byProduct = new Map<string, { sales: number; revenue: number }>()
    for (const t of success) {
      const pid = t.product_id as string
      const cur = byProduct.get(pid) || { sales: 0, revenue: 0 }
      cur.sales += 1
      cur.revenue += num(t.gross_amount)
      byProduct.set(pid, cur)
    }

    let categories: { name: string; products: number; revenue: number; percentage: number }[] = []
    let topProducts: { name: string; sales: number; revenue: number }[] = []

    const productIds = [...byProduct.keys()]
    if (productIds.length > 0) {
      const { data: prods } = await supabaseAdmin
        .from('products')
        .select('id, title, category')
        .in('id', productIds)
      const prodById = new Map((prods || []).map((p) => [p.id as string, p]))

      // Catégories
      const catAgg = new Map<string, { products: number; revenue: number }>()
      for (const [pid, agg] of byProduct) {
        const cat = (prodById.get(pid)?.category as string) || 'Autres'
        const cur = catAgg.get(cat) || { products: 0, revenue: 0 }
        cur.products += agg.sales
        cur.revenue += agg.revenue
        catAgg.set(cat, cur)
      }
      const totalCatRevenue = [...catAgg.values()].reduce((s, c) => s + c.revenue, 0) || 1
      categories = [...catAgg.entries()]
        .map(([name, c]) => ({
          name,
          products: c.products,
          revenue: Math.round(c.revenue),
          percentage: Math.round((c.revenue / totalCatRevenue) * 100),
        }))
        .sort((a, b) => b.revenue - a.revenue)

      // Top produits
      topProducts = [...byProduct.entries()]
        .map(([pid, agg]) => ({
          name: (prodById.get(pid)?.title as string) || 'Produit supprimé',
          sales: agg.sales,
          revenue: Math.round(agg.revenue),
        }))
        .sort((a, b) => b.revenue - a.revenue)
        .slice(0, 5)
    }

    return NextResponse.json({
      range,
      kpis: {
        activeUsers: activeUsers || 0,
        newUsers: newUsers || 0,
        usersTotal: usersTotal || 0,
        productsSold,
        gmv: Math.round(gmv),
        revenue: Math.round(commission),
      },
      timeseries,
      categories,
      topProducts,
      summary: {
        totalOrders: productsSold,
        avgBasket: Math.round(avgBasket),
        pendingAmount: Math.round(pendingAmount),
      },
    })
  } catch (error) {
    console.error('GET /api/analytics error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
