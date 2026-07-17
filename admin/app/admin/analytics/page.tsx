'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'
import { PieChart, TrendingUp, Users, ShoppingCart, Wallet } from 'lucide-react'

type Range = '7days' | '30days' | '90days' | 'year'

interface AnalyticsData {
  kpis: {
    activeUsers: number
    newUsers: number
    usersTotal: number
    productsSold: number
    gmv: number
    revenue: number
  }
  timeseries: { label: string; orders: number; revenue: number; signups: number }[]
  categories: { name: string; products: number; revenue: number; percentage: number }[]
  topProducts: { name: string; sales: number; revenue: number }[]
  summary: { totalOrders: number; avgBasket: number; pendingAmount: number }
}

function fcfa(n: number) {
  return `${n.toLocaleString('fr-FR')} FCFA`
}

export default function AnalyticsPage() {
  const [range, setRange] = useState<Range>('7days')

  const { data, isLoading, isError } = useQuery<AnalyticsData>({
    queryKey: ['analytics', range],
    queryFn: async () => {
      const res = await fetch(`/api/analytics?range=${range}`)
      if (!res.ok) throw new Error('Failed to fetch analytics')
      return res.json()
    },
  })

  const kpis = data
    ? [
        {
          label: 'Utilisateurs actifs',
          value: data.kpis.activeUsers.toLocaleString('fr-FR'),
          sub: `${data.kpis.usersTotal.toLocaleString('fr-FR')} au total`,
          icon: Users,
          color: 'bg-blue-500',
        },
        {
          label: 'Produits vendus',
          value: data.kpis.productsSold.toLocaleString('fr-FR'),
          sub: `${data.kpis.newUsers} nouveaux inscrits`,
          icon: ShoppingCart,
          color: 'bg-green-500',
        },
        {
          label: 'Volume de ventes (GMV)',
          value: fcfa(data.kpis.gmv),
          sub: `Panier moyen ${fcfa(data.summary.avgBasket)}`,
          icon: TrendingUp,
          color: 'bg-purple-500',
        },
        {
          label: 'Revenus MyGabon',
          value: fcfa(data.kpis.revenue),
          sub: 'Commissions + livraison',
          icon: Wallet,
          color: 'bg-orange-500',
        },
      ]
    : []

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Analytiques</h1>
          <p className="text-gray-600 mt-1">Statistiques réelles de la marketplace</p>
        </div>
        <select
          value={range}
          onChange={(e) => setRange(e.target.value as Range)}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent outline-none"
        >
          <option value="7days">7 derniers jours</option>
          <option value="30days">30 derniers jours</option>
          <option value="90days">90 derniers jours</option>
          <option value="year">Cette année</option>
        </select>
      </div>

      {isError && (
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg p-4">
          Impossible de charger les statistiques. Vérifiez la connexion à Supabase.
        </div>
      )}

      {isLoading || !data ? (
        <div className="flex items-center justify-center py-24">
          <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
        </div>
      ) : (
        <>
          {/* KPI Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {kpis.map((kpi) => {
              const Icon = kpi.icon
              return (
                <div key={kpi.label} className="bg-white rounded-lg shadow p-6">
                  <div className="flex items-start justify-between">
                    <div className="min-w-0">
                      <p className="text-gray-600 text-sm font-medium">{kpi.label}</p>
                      <p className="text-2xl font-bold text-gray-900 mt-2 truncate">{kpi.value}</p>
                      <p className="text-xs text-gray-500 mt-2">{kpi.sub}</p>
                    </div>
                    <div className={`${kpi.color} p-3 rounded-lg flex-shrink-0`}>
                      <Icon size={24} className="text-white" />
                    </div>
                  </div>
                </div>
              )
            })}
          </div>

          {/* Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="font-bold text-gray-900 mb-4">Commandes & inscriptions</h3>
              <ResponsiveContainer width="100%" height={260}>
                <LineChart data={data.timeseries}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                  <XAxis dataKey="label" tick={{ fontSize: 12 }} />
                  <YAxis tick={{ fontSize: 12 }} allowDecimals={false} />
                  <Tooltip />
                  <Line type="monotone" dataKey="orders" name="Commandes" stroke="#16a34a" strokeWidth={2} />
                  <Line type="monotone" dataKey="signups" name="Inscriptions" stroke="#2563eb" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </div>

            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="font-bold text-gray-900 mb-4">Revenus par période</h3>
              <ResponsiveContainer width="100%" height={260}>
                <BarChart data={data.timeseries}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                  <XAxis dataKey="label" tick={{ fontSize: 12 }} />
                  <YAxis tick={{ fontSize: 12 }} />
                  <Tooltip formatter={(v: number) => fcfa(v)} />
                  <Bar dataKey="revenue" name="Revenus" fill="#f97316" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Categories + Top products */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
                <PieChart size={20} />
                Ventes par catégorie
              </h3>
              {data.categories.length === 0 ? (
                <p className="text-sm text-gray-500 py-8 text-center">Aucune vente sur la période</p>
              ) : (
                <div className="space-y-4">
                  {data.categories.map((cat) => (
                    <div key={cat.name}>
                      <div className="flex items-center justify-between mb-2">
                        <div>
                          <p className="font-medium text-gray-900">{cat.name}</p>
                          <p className="text-xs text-gray-600">{cat.products} vente(s)</p>
                        </div>
                        <p className="font-bold text-gray-900">{fcfa(cat.revenue)}</p>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2">
                        <div
                          className="bg-primary rounded-full h-2 transition-all"
                          style={{ width: `${cat.percentage}%` }}
                        ></div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="font-bold text-gray-900 mb-4">Produits les plus vendus</h3>
              {data.topProducts.length === 0 ? (
                <p className="text-sm text-gray-500 py-8 text-center">Aucune vente sur la période</p>
              ) : (
                <div className="space-y-4">
                  {data.topProducts.map((product, idx) => (
                    <div key={product.name + idx} className="flex items-center justify-between">
                      <div className="flex items-center gap-2 min-w-0">
                        <span className="text-sm font-semibold text-gray-600">#{idx + 1}</span>
                        <p className="font-medium text-gray-900 truncate">{product.name}</p>
                      </div>
                      <div className="text-right flex-shrink-0 ml-2">
                        <p className="font-bold text-gray-900">{product.sales} vente(s)</p>
                        <p className="text-xs text-gray-600">{fcfa(product.revenue)}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Summary */}
          <div className="bg-gradient-to-r from-primary/10 to-primary/5 rounded-lg p-6 border border-primary/20">
            <h3 className="font-bold text-gray-900 mb-4">Résumé de la période</h3>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              <div>
                <p className="text-gray-600 text-sm">Commandes réussies</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">
                  {data.summary.totalOrders.toLocaleString('fr-FR')}
                </p>
              </div>
              <div>
                <p className="text-gray-600 text-sm">Panier moyen</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">{fcfa(data.summary.avgBasket)}</p>
              </div>
              <div>
                <p className="text-gray-600 text-sm">En attente (COD)</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">{fcfa(data.summary.pendingAmount)}</p>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
