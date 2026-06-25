'use client'

import { useState } from 'react'
import { BarChart, LineChart, PieChart, TrendingUp, Users, ShoppingCart, Eye } from 'lucide-react'

export default function AnalyticsPage() {
  const [dateRange, setDateRange] = useState('7days')

  // Mock data - would be replaced with real API calls
  const kpis = [
    {
      label: 'Utilisateurs Actifs',
      value: '3,847',
      icon: Users,
      color: 'bg-blue-500',
      trend: '+12.5%',
    },
    {
      label: 'Produits Vendus',
      value: '1,264',
      icon: ShoppingCart,
      color: 'bg-green-500',
      trend: '+8.2%',
    },
    {
      label: 'Vues Totales',
      value: '45,230',
      icon: Eye,
      color: 'bg-purple-500',
      trend: '+15.3%',
    },
    {
      label: 'Revenus',
      value: '2.4M FCFA',
      icon: TrendingUp,
      color: 'bg-orange-500',
      trend: '+22.1%',
    },
  ]

  const chartData = [
    { day: 'Lun', users: 120, products: 45, revenue: 1200 },
    { day: 'Mar', users: 150, products: 52, revenue: 1500 },
    { day: 'Mer', users: 130, products: 48, revenue: 1300 },
    { day: 'Jeu', users: 180, products: 65, revenue: 1800 },
    { day: 'Ven', users: 200, products: 78, revenue: 2000 },
    { day: 'Sam', users: 220, products: 85, revenue: 2200 },
    { day: 'Dim', users: 190, products: 72, revenue: 1900 },
  ]

  const categories = [
    { name: 'Électronique', products: 456, revenue: 850000, percentage: 35 },
    { name: 'Vêtements', products: 328, revenue: 620000, percentage: 25 },
    { name: 'Alimentation', products: 287, revenue: 490000, percentage: 20 },
    { name: 'Maison', products: 186, revenue: 380000, percentage: 15 },
    { name: 'Autres', products: 107, revenue: 160000, percentage: 5 },
  ]

  const topProducts = [
    { name: 'Produit A', sales: 127, revenue: 320000, rating: 4.8 },
    { name: 'Produit B', sales: 98, revenue: 245000, rating: 4.6 },
    { name: 'Produit C', sales: 87, revenue: 218000, rating: 4.5 },
    { name: 'Produit D', sales: 76, revenue: 190000, rating: 4.4 },
    { name: 'Produit E', sales: 65, revenue: 162000, rating: 4.3 },
  ]

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Analytiques</h1>
          <p className="text-gray-600 mt-1">Suivi des performances et des tendances</p>
        </div>
        <select
          value={dateRange}
          onChange={(e) => setDateRange(e.target.value)}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent outline-none"
        >
          <option value="7days">7 derniers jours</option>
          <option value="30days">30 derniers jours</option>
          <option value="90days">90 derniers jours</option>
          <option value="year">Cette année</option>
        </select>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {kpis.map((kpi) => {
          const Icon = kpi.icon
          return (
            <div key={kpi.label} className="bg-white rounded-lg shadow p-6">
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-gray-600 text-sm font-medium">{kpi.label}</p>
                  <p className="text-2xl font-bold text-gray-900 mt-2">{kpi.value}</p>
                  <p className="text-xs text-green-600 mt-2">{kpi.trend}</p>
                </div>
                <div className={`${kpi.color} p-3 rounded-lg`}>
                  <Icon size={24} className="text-white" />
                </div>
              </div>
            </div>
          )
        })}
      </div>

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Activity Chart */}
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
            <LineChart size={20} />
            Activité par Jour
          </h3>
          <div className="h-64 flex items-end justify-around gap-2">
            {chartData.map((data) => (
              <div key={data.day} className="text-center flex-1">
                <div className="relative h-40 flex flex-col items-end justify-end">
                  <div
                    className="w-full bg-gradient-to-t from-primary to-primary/60 rounded-t"
                    style={{
                      height: `${(data.users / 250) * 100}%`,
                    }}
                  ></div>
                </div>
                <p className="text-xs text-gray-600 mt-2">{data.day}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Revenue Chart */}
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
            <BarChart size={20} />
            Revenus par Jour
          </h3>
          <div className="h-64 flex items-end justify-around gap-2">
            {chartData.map((data) => (
              <div key={data.day} className="text-center flex-1">
                <div className="relative h-40 flex flex-col items-end justify-end">
                  <div
                    className="w-full bg-gradient-to-t from-green-500 to-green-400 rounded-t"
                    style={{
                      height: `${(data.revenue / 2500) * 100}%`,
                    }}
                  ></div>
                </div>
                <p className="text-xs text-gray-600 mt-2">{data.day}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Categories */}
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
            <PieChart size={20} />
            Ventes par Catégorie
          </h3>
          <div className="space-y-4">
            {categories.map((cat) => (
              <div key={cat.name}>
                <div className="flex items-center justify-between mb-2">
                  <div>
                    <p className="font-medium text-gray-900">{cat.name}</p>
                    <p className="text-xs text-gray-600">{cat.products} produits</p>
                  </div>
                  <p className="font-bold text-gray-900">{cat.revenue.toLocaleString()} FCFA</p>
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
        </div>

        {/* Top Products */}
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="font-bold text-gray-900 mb-4">Produits Les Plus Vendus</h3>
          <div className="space-y-4">
            {topProducts.map((product, idx) => (
              <div key={product.name} className="flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-semibold text-gray-600">#{idx + 1}</span>
                    <p className="font-medium text-gray-900">{product.name}</p>
                  </div>
                  <div className="flex items-center gap-2 mt-1">
                    <div className="flex">
                      {Array.from({ length: 5 }).map((_, i) => (
                        <span
                          key={i}
                          className={`text-xs ${i < Math.floor(product.rating) ? '⭐' : '☆'}`}
                        >
                          {i < Math.floor(product.rating) ? '★' : '☆'}
                        </span>
                      ))}
                    </div>
                    <span className="text-xs text-gray-600">{product.rating}</span>
                  </div>
                </div>
                <div className="text-right">
                  <p className="font-bold text-gray-900">{product.sales}</p>
                  <p className="text-xs text-gray-600">{product.revenue.toLocaleString()} FCFA</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Summary Stats */}
      <div className="bg-gradient-to-r from-primary/10 to-primary/5 rounded-lg p-6 border border-primary/20">
        <h3 className="font-bold text-gray-900 mb-4">Résumé de la Période</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <p className="text-gray-600 text-sm">Commandes Totales</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">1,247</p>
          </div>
          <div>
            <p className="text-gray-600 text-sm">Taux de Conversion</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">3.2%</p>
          </div>
          <div>
            <p className="text-gray-600 text-sm">Panier Moyen</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">1,924 FCFA</p>
          </div>
          <div>
            <p className="text-gray-600 text-sm">Taux de Satisfaction</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">4.6/5</p>
          </div>
        </div>
      </div>
    </div>
  )
}
