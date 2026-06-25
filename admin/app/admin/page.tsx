'use client'

import { useSession } from 'next-auth/react'
import { useUsers } from '@/lib/hooks/useUsers'
import { useImageQueue } from '@/lib/hooks/useImages'
import { Users, ImageIcon, TrendingUp, AlertCircle } from 'lucide-react'
import Link from 'next/link'

export default function AdminDashboard() {
  const { data: session } = useSession()
  const { data: usersData, isLoading: usersLoading } = useUsers(1, '', '')
  const { data: imagesData, isLoading: imagesLoading } = useImageQueue('pending', 1)

  const stats = [
    {
      label: 'Utilisateurs Totaux',
      value: usersData?.pagination?.total || 0,
      icon: Users,
      color: 'bg-blue-500',
      href: '/admin/users',
    },
    {
      label: 'Images en Attente',
      value: imagesData?.pagination?.total || 0,
      icon: ImageIcon,
      color: 'bg-orange-500',
      href: '/admin/images',
    },
    {
      label: 'Rôle',
      value: (session?.user as any)?.role || 'N/A',
      icon: TrendingUp,
      color: 'bg-green-500',
      href: '#',
    },
  ]

  return (
    <div className="space-y-8">
      {/* Welcome Section */}
      <div>
        <h2 className="text-3xl font-bold text-gray-900">Bienvenue, {session?.user?.name}</h2>
        <p className="text-gray-600 mt-2">Voici un aperçu de votre tableau de bord</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {stats.map((stat) => {
          const Icon = stat.icon
          return (
            <Link
              key={stat.label}
              href={stat.href}
              className="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow cursor-pointer"
            >
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-gray-600 text-sm font-medium">{stat.label}</p>
                  <p className="text-3xl font-bold text-gray-900 mt-2">
                    {typeof stat.value === 'number' ? stat.value.toLocaleString() : stat.value}
                  </p>
                </div>
                <div className={`${stat.color} p-3 rounded-lg`}>
                  <Icon size={24} className="text-white" />
                </div>
              </div>
            </Link>
          )
        })}
      </div>

      {/* Quick Actions */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Actions Rapides</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Link
            href="/admin/users?action=create"
            className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <p className="font-medium text-gray-900">Ajouter un Utilisateur</p>
            <p className="text-sm text-gray-600 mt-1">Créer un nouveau compte utilisateur</p>
          </Link>
          <Link
            href="/admin/images"
            className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <p className="font-medium text-gray-900">Modérer les Images</p>
            <p className="text-sm text-gray-600 mt-1">Traiter les images en attente</p>
          </Link>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Informations Système</h3>
        <div className="space-y-3">
          <div className="flex items-center gap-3 p-3 bg-blue-50 rounded-lg">
            <AlertCircle size={20} className="text-blue-600" />
            <div>
              <p className="font-medium text-blue-900">Système opérationnel</p>
              <p className="text-sm text-blue-700">Tous les services fonctionnent correctement</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
