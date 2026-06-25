'use client'

import { useState } from 'react'
import { Wallet, TrendingUp, TrendingDown, DollarSign, Filter } from 'lucide-react'

export default function WalletPage() {
  const [page, setPage] = useState(1)
  const [filter, setFilter] = useState('all')

  // Mock data - would be replaced with real API calls
  const stats = [
    {
      label: 'Volume Total',
      value: '2,450,000 FCFA',
      icon: DollarSign,
      color: 'bg-blue-500',
      change: '+12.5%',
    },
    {
      label: 'Transactions Actives',
      value: '1,247',
      icon: TrendingUp,
      color: 'bg-green-500',
      change: '+8.2%',
    },
    {
      label: 'En Attente',
      value: '125,500 FCFA',
      icon: TrendingDown,
      color: 'bg-orange-500',
      change: '-2.1%',
    },
    {
      label: 'Frais Collectés',
      value: '45,200 FCFA',
      icon: Wallet,
      color: 'bg-purple-500',
      change: '+15.3%',
    },
  ]

  const transactions = [
    {
      id: 1,
      user: 'Jean Dupont',
      type: 'deposit',
      amount: 50000,
      status: 'completed',
      date: '2026-06-24',
      method: 'Airtel Money',
    },
    {
      id: 2,
      user: 'Marie Sow',
      type: 'withdrawal',
      amount: 25000,
      status: 'pending',
      date: '2026-06-24',
      method: 'MyGabon',
    },
    {
      id: 3,
      user: 'Paul Nzi',
      type: 'transfer',
      amount: 15000,
      status: 'completed',
      date: '2026-06-23',
      method: 'MyGabon',
    },
    {
      id: 4,
      user: 'Sophie Ondo',
      type: 'deposit',
      amount: 75000,
      status: 'completed',
      date: '2026-06-23',
      method: 'Airtel Money',
    },
    {
      id: 5,
      user: 'Ahmed Bah',
      type: 'withdrawal',
      amount: 30000,
      status: 'failed',
      date: '2026-06-22',
      method: 'MyGabon',
    },
  ]

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Gestion du Portefeuille</h1>
        <p className="text-gray-600 mt-1">Suivi des transactions et des soldes</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => {
          const Icon = stat.icon
          return (
            <div key={stat.label} className="bg-white rounded-lg shadow p-6">
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-gray-600 text-sm font-medium">{stat.label}</p>
                  <p className="text-2xl font-bold text-gray-900 mt-2">{stat.value}</p>
                  <p className="text-xs text-green-600 mt-2">{stat.change}</p>
                </div>
                <div className={`${stat.color} p-3 rounded-lg`}>
                  <Icon size={24} className="text-white" />
                </div>
              </div>
            </div>
          )
        })}
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex items-center gap-4">
          <Filter size={20} className="text-gray-600" />
          <select
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent outline-none"
          >
            <option value="all">Toutes les transactions</option>
            <option value="deposit">Dépôts</option>
            <option value="withdrawal">Retraits</option>
            <option value="transfer">Transferts</option>
            <option value="pending">En attente</option>
            <option value="completed">Complétées</option>
            <option value="failed">Échouées</option>
          </select>
        </div>
      </div>

      {/* Transactions Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Utilisateur</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Type</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Montant</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Méthode</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Statut</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {transactions.map((tx) => (
                <tr key={tx.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 text-sm text-gray-900 font-medium">{tx.user}</td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    <span className="capitalize">{tx.type}</span>
                  </td>
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">
                    {tx.amount.toLocaleString()} FCFA
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">{tx.method}</td>
                  <td className="px-6 py-4 text-sm">
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-medium ${
                        tx.status === 'completed'
                          ? 'bg-green-100 text-green-800'
                          : tx.status === 'pending'
                            ? 'bg-yellow-100 text-yellow-800'
                            : 'bg-red-100 text-red-800'
                      }`}
                    >
                      {tx.status === 'completed'
                        ? 'Complétée'
                        : tx.status === 'pending'
                          ? 'En attente'
                          : 'Échouée'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {new Date(tx.date).toLocaleDateString('fr-FR')}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="flex items-center justify-between px-6 py-4 border-t border-gray-200 bg-gray-50">
          <div className="text-sm text-gray-600">Page 1 sur 1</div>
          <div className="flex gap-2">
            <button
              disabled
              className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
            >
              Précédent
            </button>
            <button
              disabled
              className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
            >
              Suivant
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
