'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useUsers, useDeleteUser } from '@/lib/hooks/useUsers'
import { Search, Plus, Trash2, Eye, Filter } from 'lucide-react'

export default function UsersPage() {
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [debouncedSearch, setDebouncedSearch] = useState('')

  const { data, isLoading } = useUsers(page, debouncedSearch, status)
  const deleteUser = useDeleteUser()

  // Debounce search
  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearch(e.target.value)
    const timer = setTimeout(() => {
      setDebouncedSearch(e.target.value)
      setPage(1)
    }, 300)
    return () => clearTimeout(timer)
  }

  const handleDelete = async (userId: string) => {
    if (confirm('Êtes-vous sûr de vouloir supprimer cet utilisateur?')) {
      await deleteUser.mutateAsync(userId)
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Gestion des Utilisateurs</h1>
          <p className="text-gray-600 mt-1">Gérez les comptes utilisateurs MyGabon</p>
        </div>
        <Link
          href="/admin/users/create"
          className="flex items-center gap-2 bg-primary hover:bg-primary/90 text-white px-4 py-2 rounded-lg transition-colors"
        >
          <Plus size={20} />
          Ajouter Utilisateur
        </Link>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-3 text-gray-400" size={20} />
            <input
              type="text"
              placeholder="Rechercher par email ou nom..."
              value={search}
              onChange={handleSearch}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent outline-none"
            />
          </div>

          {/* Status Filter */}
          <select
            value={status}
            onChange={(e) => {
              setStatus(e.target.value)
              setPage(1)
            }}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent outline-none"
          >
            <option value="">Tous les statuts</option>
            <option value="active">Actif</option>
            <option value="inactive">Inactif</option>
            <option value="suspended">Suspendu</option>
            <option value="deleted">Supprimé</option>
          </select>

          {/* Stats */}
          <div className="flex items-center gap-2 text-gray-600">
            <Filter size={20} />
            <span>
              {data?.pagination?.total || 0} utilisateur(s) trouvé(s)
            </span>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Email</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Nom</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Statut</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Date de création</th>
                <th className="px-6 py-3 text-right text-sm font-semibold text-gray-900">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {isLoading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center">
                    <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                  </td>
                </tr>
              ) : data?.data?.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                    Aucun utilisateur trouvé
                  </td>
                </tr>
              ) : (
                data?.data?.map((user: any) => (
                  <tr key={user.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-900 font-medium">{user.email}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{user.full_name}</td>
                    <td className="px-6 py-4 text-sm">
                      <span
                        className={`px-3 py-1 rounded-full text-xs font-medium ${
                          user.status === 'active'
                            ? 'bg-green-100 text-green-800'
                            : user.status === 'suspended'
                              ? 'bg-red-100 text-red-800'
                              : user.status === 'inactive'
                                ? 'bg-yellow-100 text-yellow-800'
                                : 'bg-gray-100 text-gray-800'
                        }`}
                      >
                        {user.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {new Date(user.created_at).toLocaleDateString('fr-FR')}
                    </td>
                    <td className="px-6 py-4 text-right space-x-2 flex justify-end">
                      <Link
                        href={`/admin/users/${user.id}`}
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        title="Voir détails"
                      >
                        <Eye size={18} className="text-gray-600" />
                      </Link>
                      <button
                        onClick={() => handleDelete(user.id)}
                        disabled={deleteUser.isPending}
                        className="p-2 hover:bg-red-50 rounded-lg transition-colors disabled:opacity-50"
                        title="Supprimer"
                      >
                        <Trash2 size={18} className="text-red-600" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
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
