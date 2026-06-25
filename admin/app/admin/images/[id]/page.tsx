'use client'

import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import { useImageDetails, useApproveImage, useRejectImage } from '@/lib/hooks/useImages'
import { ArrowLeft, AlertCircle, CheckCircle, XCircle } from 'lucide-react'
import { useState } from 'react'

export default function ImageDetailPage() {
  const params = useParams()
  const router = useRouter()
  const imageId = params.id as string
  const { data: image, isLoading } = useImageDetails(imageId)
  const approveImage = useApproveImage()
  const rejectImage = useRejectImage()

  const [showRejectForm, setShowRejectForm] = useState(false)
  const [rejectReason, setRejectReason] = useState('')
  const [rejectNotes, setRejectNotes] = useState('')

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  if (!image) {
    return (
      <div className="text-center py-12">
        <AlertCircle size={48} className="mx-auto text-red-500 mb-4" />
        <p className="text-gray-600">Image non trouvée</p>
        <Link href="/admin/images" className="text-primary hover:underline mt-4 inline-block">
          Retour à la liste
        </Link>
      </div>
    )
  }

  const handleApprove = async () => {
    try {
      await approveImage.mutateAsync({ imageId })
      router.push('/admin/images')
    } catch (error) {
      console.error('Erreur lors de l\'approbation:', error)
    }
  }

  const handleReject = async () => {
    if (!rejectReason) {
      alert('Veuillez sélectionner une raison')
      return
    }

    try {
      await rejectImage.mutateAsync({
        imageId,
        reason: rejectReason,
        notes: rejectNotes,
      })
      router.push('/admin/images')
    } catch (error) {
      console.error('Erreur lors du rejet:', error)
    }
  }

  const statusConfig: Record<string, { bg: string; text: string }> = {
    pending: { bg: 'bg-yellow-100', text: 'text-yellow-800' },
    approved: { bg: 'bg-green-100', text: 'text-green-800' },
    rejected: { bg: 'bg-red-100', text: 'text-red-800' },
    flagged: { bg: 'bg-orange-100', text: 'text-orange-800' },
    under_review: { bg: 'bg-blue-100', text: 'text-blue-800' },
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link
          href="/admin/images"
          className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
        >
          <ArrowLeft size={24} />
        </Link>
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Détails de l'Image</h1>
          <p className="text-gray-600 mt-1">ID: {imageId}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Image Preview */}
        <div className="lg:col-span-2">
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <div className="w-full bg-gray-100 flex items-center justify-center" style={{ minHeight: '500px' }}>
              <img
                src={image.image_url}
                alt="Product"
                className="max-w-full max-h-full object-contain"
                onError={(e) => {
                  ;(e.target as HTMLImageElement).src = '/placeholder.png'
                }}
              />
            </div>
          </div>
        </div>

        {/* Sidebar Info */}
        <div className="space-y-6">
          {/* Status */}
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="font-bold text-gray-900 mb-4">Statut</h3>
            <span
              className={`inline-block px-4 py-2 rounded-full text-sm font-medium ${statusConfig[image.status].bg} ${statusConfig[image.status].text}`}
            >
              {image.status.replace('_', ' ').toUpperCase()}
            </span>
          </div>

          {/* AI Analysis */}
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="font-bold text-gray-900 mb-4">Analyse IA</h3>
            <div className="space-y-3">
              {/* Nudity Score */}
              <div>
                <div className="flex justify-between mb-2">
                  <span className="text-sm font-medium text-gray-700">Nudité</span>
                  <span className="text-sm font-bold text-gray-900">
                    {(image.ai_nudity_score * 100).toFixed(0)}%
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full ${
                      image.ai_nudity_score > 0.5 ? 'bg-red-500' : 'bg-green-500'
                    }`}
                    style={{ width: `${image.ai_nudity_score * 100}%` }}
                  ></div>
                </div>
              </div>

              {/* Violence Score */}
              <div>
                <div className="flex justify-between mb-2">
                  <span className="text-sm font-medium text-gray-700">Violence</span>
                  <span className="text-sm font-bold text-gray-900">
                    {(image.ai_violence_score * 100).toFixed(0)}%
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full ${
                      image.ai_violence_score > 0.5 ? 'bg-red-500' : 'bg-green-500'
                    }`}
                    style={{ width: `${image.ai_violence_score * 100}%` }}
                  ></div>
                </div>
              </div>

              {/* Illegal Content Score */}
              <div>
                <div className="flex justify-between mb-2">
                  <span className="text-sm font-medium text-gray-700">Contenu illégal</span>
                  <span className="text-sm font-bold text-gray-900">
                    {(image.ai_illegal_score * 100).toFixed(0)}%
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full ${
                      image.ai_illegal_score > 0.5 ? 'bg-red-500' : 'bg-green-500'
                    }`}
                    style={{ width: `${image.ai_illegal_score * 100}%` }}
                  ></div>
                </div>
              </div>

              {/* Quality Score */}
              <div>
                <div className="flex justify-between mb-2">
                  <span className="text-sm font-medium text-gray-700">Qualité</span>
                  <span className="text-sm font-bold text-gray-900">
                    {(image.ai_quality_score * 100).toFixed(0)}%
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full bg-blue-500`}
                    style={{ width: `${image.ai_quality_score * 100}%` }}
                  ></div>
                </div>
              </div>
            </div>

            {image.ai_recommendation && (
              <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded text-sm text-blue-800">
                💡 {image.ai_recommendation}
              </div>
            )}
          </div>

          {/* Metadata */}
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="font-bold text-gray-900 mb-4">Métadonnées</h3>
            <div className="space-y-2 text-sm">
              <div>
                <p className="text-gray-600">Produit ID</p>
                <p className="text-gray-900 font-mono text-xs break-all">{image.product_id}</p>
              </div>
              <div>
                <p className="text-gray-600">Créée le</p>
                <p className="text-gray-900">
                  {new Date(image.created_at).toLocaleDateString('fr-FR', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </p>
              </div>
              {image.reviewed_at && (
                <div>
                  <p className="text-gray-600">Révisée par</p>
                  <p className="text-gray-900">{image.reviewed_by || 'Système'}</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Actions Section */}
      {image.status === 'pending' && (
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="font-bold text-gray-900 mb-6">Actions de Modération</h3>

          {!showRejectForm ? (
            <div className="flex gap-4">
              <button
                onClick={handleApprove}
                disabled={approveImage.isPending}
                className="flex items-center gap-2 px-6 py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors disabled:opacity-50 font-medium"
              >
                <CheckCircle size={20} />
                Approuver l'Image
              </button>
              <button
                onClick={() => setShowRejectForm(true)}
                className="flex items-center gap-2 px-6 py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg transition-colors font-medium"
              >
                <XCircle size={20} />
                Rejeter l'Image
              </button>
            </div>
          ) : (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Raison du rejet <span className="text-red-500">*</span>
                </label>
                <select
                  value={rejectReason}
                  onChange={(e) => setRejectReason(e.target.value)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent outline-none"
                >
                  <option value="">Sélectionner une raison...</option>
                  <option value="nudity">Contenu nu/sexuel</option>
                  <option value="violence">Contenu violent</option>
                  <option value="illegal">Contenu illégal</option>
                  <option value="quality">Mauvaise qualité</option>
                  <option value="inappropriate">Contenu inapproprié</option>
                  <option value="other">Autre</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Notes (optionnel)</label>
                <textarea
                  value={rejectNotes}
                  onChange={(e) => setRejectNotes(e.target.value)}
                  placeholder="Ajouter des notes supplémentaires..."
                  rows={3}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent outline-none"
                />
              </div>

              <div className="flex gap-3">
                <button
                  onClick={handleReject}
                  disabled={rejectImage.isPending || !rejectReason}
                  className="flex items-center gap-2 px-6 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg transition-colors disabled:opacity-50 font-medium"
                >
                  <XCircle size={18} />
                  Confirmer le Rejet
                </button>
                <button
                  onClick={() => {
                    setShowRejectForm(false)
                    setRejectReason('')
                    setRejectNotes('')
                  }}
                  className="px-6 py-2 border border-gray-300 text-gray-700 hover:bg-gray-50 rounded-lg transition-colors font-medium"
                >
                  Annuler
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
