'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Wallet, TrendingUp, Clock, DollarSign, Filter } from 'lucide-react'

interface WalletData {
  stats: {
    totalBalance: number
    successCount: number
    pendingAmount: number
    feesCollected: number
  }
  transactions: {
    id: string
    user: string
    amount: number
    method: string
    status: string
    date: string
  }[]
  pagination: { page: number; limit: number; total: number; pages: number }
}

function fcfa(n: number) {
  return `${n.toLocaleString('fr-FR')} FCFA`
}

const STATUS_STYLE: Record<string, { label: string; cls: string }> = {
  success: { label: 'Réussie', cls: 'bg-green-100 text-green-800' },
  pending: { label: 'En attente', cls: 'bg-yellow-100 text-yellow-800' },
  failed: { label: 'Échouée', cls: 'bg-red-100 text-red-800' },
}

export default function WalletPage() {
  const [page, setPage] = useState(1)
  const [filter, setFilter] = useState('all')

  const { data, isLoading } = useQuery<WalletData>({
    queryKey: ['wallet', page, filter],
    queryFn: async () => {
      const res = await fetch(`/api/wallet?page=${page}&filter=${filter}`)
      if (!res.ok) throw new Error('Failed to fetch wallet')
      return res.json()
    },
  })

  const stats = data
    ? [
        {
          label: 'Solde total en circulation',
          value: fcfa(data.stats.totalBalance),
          icon: DollarSign,
          color: 'bg-blue-500',
        },
        {
          label: 'Transactions réussies',
          value: data.stats.successCount.toLocaleString('fr-FR'),
          icon: TrendingUp,
          color: 'bg-green-500',
        },
        {
          label: 'En attente (COD)',
          value: fcfa(data.stats.pendingAmount),
          icon: Clock,
          color: 'bg-orange-500',
        },
        {
          label: 'Frais collectés',
          value: fcfa(data.stats.feesCollected),
          icon: Wallet,
          color: 'bg-purple-500',
        },
      ]
    : []

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Gestion du portefeuille</h1>
        <p className="text-gray-600 mt-1">Suivi des transactions et des soldes</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {isLoading || !data
          ? Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="bg-white rounded-lg shadow p-6 h-28 animate-pulse" />
            ))
          : stats.map((stat) => {
              const Icon = stat.icon
              return (
                <div key={stat.label} className="bg-white rounded-lg shadow p-6">
                  <div className="flex items-start justify-between">
                    <div className="min-w-0">
                      <p className="text-gray-600 text-sm font-medium">{stat.label}</p>
                      <p className="text-2xl font-bold text-gray-900 mt-2 truncate">{stat.value}</p>
                    </div>
                    <div className={`${stat.color} p-3 rounded-lg flex-shrink-0`}>
                      <Icon size={24} className="text-white" />
                    </div>
                  </div>
                </div>
              )
            })}
      </div>

      {/* Filter */}
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex items-center gap-4">
          <Filter size={20} className="text-gray-600" />
          <select
            value={filter}
            onChange={(e) => {
              setFilter(e.target.value)
              setPage(1)
            }}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent outline-none"
          >
            <option value="all">Toutes les transactions</option>
            <option value="success">Réussies</option>
            <option value="pending">En attente</option>
            <option value="failed">Échouées</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Acheteur</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Montant</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Méthode</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Statut</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {isLoading || !data ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center">
                    <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                  </td>
                </tr>
              ) : data.transactions.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                    Aucune transaction
                  </td>
                </tr>
              ) : (
                data.transactions.map((tx) => {
                  const st = STATUS_STYLE[tx.status] || { label: tx.status, cls: 'bg-gray-100 text-gray-800' }
                  return (
                    <tr key={tx.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-sm text-gray-900 font-medium">{tx.user}</td>
                      <td className="px-6 py-4 text-sm font-medium text-gray-900">{fcfa(tx.amount)}</td>
                      <td className="px-6 py-4 text-sm text-gray-600">{tx.method}</td>
                      <td className="px-6 py-4 text-sm">
                        <span className={`px-3 py-1 rounded-full text-xs font-medium ${st.cls}`}>
                          {st.label}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">
                        {new Date(tx.date).toLocaleDateString('fr-FR')}
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>

        {data?.pagination && data.pagination.pages > 1 && (
          <div className="flex items-center justify-between px-6 py-4 border-t border-gray-200 bg-gray-50">
            <div className="text-sm text-gray-600">
              Page {data.pagination.page} sur {data.pagination.pages}
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => setPage(Math.max(1, page - 1))}
                disabled={page === 1}
                className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
              >
                Précédent
              </button>
              <button
                onClick={() => setPage(Math.min(data.pagination.pages, page + 1))}
                disabled={page === data.pagination.pages}
                className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
              >
                Suivant
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
