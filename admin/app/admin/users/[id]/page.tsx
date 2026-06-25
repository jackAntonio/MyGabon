'use client'

import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import { useUser, useUpdateUser, type User } from '@/lib/hooks/useUsers'
import { ArrowLeft, Save, AlertCircle } from 'lucide-react'
import { useState } from 'react'

export default function UserDetailPage() {
  const params = useParams()
  const router = useRouter()
  const userId = params.id as string
  const { data: user, isLoading } = useUser(userId)
  const updateUser = useUpdateUser()

  const [editMode, setEditMode] = useState(false)
  // Pas d'email ici : modifier users.email depuis ce formulaire ne mettrait
  // pas à jour le compte Supabase Auth associé (désynchronisation login/email
  // affiché). L'API /api/users/[id] ignore d'ailleurs ce champ (cf. UPDATABLE_USER_FIELDS).
  const [formData, setFormData] = useState<Pick<User, 'full_name' | 'status'>>({
    full_name: '',
    status: 'active',
  })

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  if (!user) {
    return (
      <div className="text-center py-12">
        <AlertCircle size={48} className="mx-auto text-red-500 mb-4" />
        <p className="text-gray-600">Utilisateur non trouvé</p>
        <Link href="/admin/users" className="text-primary hover:underline mt-4 inline-block">
          Retour à la liste
        </Link>
      </div>
    )
  }

  const handleEdit = () => {
    setFormData({
      full_name: user.full_name,
      status: user.status,
    })
    setEditMode(true)
  }

  const handleSave = async () => {
    try {
      await updateUser.mutateAsync({
        userId,
        data: formData,
      })
      setEditMode(false)
    } catch (error) {
      console.error('Erreur lors de la mise à jour:', error)
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link
          href="/admin/users"
          className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
        >
          <ArrowLeft size={24} />
        </Link>
        <div>
          <h1 className="text-3xl font-bold text-gray-900">{user.full_name}</h1>
          <p className="text-gray-600 mt-1">{user.email}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Info */}
        <div className="lg:col-span-2 space-y-6">
          {/* User Details Card */}
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-gray-900">Informations Utilisateur</h2>
              {!editMode && (
                <button
                  onClick={handleEdit}
                  className="px-4 py-2 bg-primary hover:bg-primary/90 text-white rounded-lg transition-colors text-sm"
                >
                  Modifier
                </button>
              )}
            </div>

            <div className="space-y-4">
              {/* Full Name */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Nom complet</label>
                {editMode ? (
                  <input
                    type="text"
                    value={formData.full_name}
                    onChange={(e) =>
                      setFormData({ ...formData, full_name: e.target.value })
                    }
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent outline-none"
                  />
                ) : (
                  <p className="text-gray-900">{user.full_name}</p>
                )}
              </div>

              {/* Email (lecture seule : géré par Supabase Auth, pas par cette API) */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Email</label>
                <p className="text-gray-900">{user.email}</p>
              </div>

              {/* Status */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Statut</label>
                {editMode ? (
                  <select
                    value={formData.status}
                    onChange={(e) =>
                      setFormData({ ...formData, status: e.target.value as User['status'] })
                    }
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent outline-none"
                  >
                    <option value="active">Actif</option>
                    <option value="suspended">Suspendu</option>
                  </select>
                ) : (
                  <span
                    className={`inline-block px-3 py-1 rounded-full text-sm font-medium ${
                      user.status === 'active'
                        ? 'bg-green-100 text-green-800'
                        : user.status === 'suspended'
                          ? 'bg-red-100 text-red-800'
                          : 'bg-yellow-100 text-yellow-800'
                    }`}
                  >
                    {user.status}
                  </span>
                )}
              </div>

              {/* Edit Actions */}
              {editMode && (
                <div className="flex gap-3 pt-4">
                  <button
                    onClick={handleSave}
                    disabled={updateUser.isPending}
                    className="flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-white rounded-lg transition-colors disabled:opacity-50"
                  >
                    <Save size={18} />
                    Enregistrer
                  </button>
                  <button
                    onClick={() => setEditMode(false)}
                    className="px-4 py-2 border border-gray-300 text-gray-700 hover:bg-gray-50 rounded-lg transition-colors"
                  >
                    Annuler
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Sidebar Info */}
        <div className="space-y-6">
          {/* Metadata */}
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="font-bold text-gray-900 mb-4">Métadonnées</h3>
            <div className="space-y-3 text-sm">
              <div>
                <p className="text-gray-600">Créé le</p>
                <p className="text-gray-900 font-medium">
                  {new Date(user.created_at).toLocaleDateString('fr-FR', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </p>
              </div>
              <div>
                <p className="text-gray-600">Mis à jour le</p>
                <p className="text-gray-900 font-medium">
                  {new Date(user.updated_at).toLocaleDateString('fr-FR', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </p>
              </div>
              <div>
                <p className="text-gray-600">ID</p>
                <p className="text-gray-900 font-mono text-xs break-all">{user.id}</p>
              </div>
            </div>
          </div>

          {/* Quick Stats */}
          <div className="bg-blue-50 rounded-lg p-4 border border-blue-200">
            <h3 className="font-bold text-blue-900 mb-2">ℹ️ Information</h3>
            <p className="text-sm text-blue-800">
              Cet utilisateur peut accéder à la plateforme MyGabon pour acheter et vendre des produits.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
