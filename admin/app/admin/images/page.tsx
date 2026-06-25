'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useImageQueue } from '@/lib/hooks/useImages'
import { Eye, Filter, CheckCircle, XCircle } from 'lucide-react'

export default function ImagesPage() {
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState('pending')

  const { data, isLoading } = useImageQueue(status, page)

  const statusConfig: Record<string, { bg: string; text: string; label: string }> = {
    pending: { bg: 'bg-yellow-100', text: 'text-yellow-800', label: 'En attente' },
    approved: { bg: 'bg-green-100', text: 'text-green-800', label: 'Approuvée' },
    rejected: { bg: 'bg-red-100', text: 'text-red-800', label: 'Rejetée' },
    flagged: { bg: 'bg-orange-100', text: 'text-orange-800', label: 'Signalée' },
    under_review: { bg: 'bg-blue-100', text: 'text-blue-800', label: 'En révision' },
  }

  const statuses = ['pending', 'under_review', 'approved', 'rejected', 'flagged']

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Modération des Images</h1>
          <p className="text-gray-600 mt-1">Examiner et valider les images des produits</p>
        </div>
      </div>

      {/* Status Tabs */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="flex border-b border-gray-200">
          {statuses.map((s) => (
            <button
              key={s}
              onClick={() => {
                setStatus(s)
                setPage(1)
              }}
              className={`flex-1 px-4 py-4 text-center font-medium transition-colors border-b-2 ${
                status === s
                  ? 'border-primary text-primary'
                  : 'border-transparent text-gray-600 hover:text-gray-900'
              }`}
            >
              {statusConfig[s].label}
              {data?.pagination?.total !== undefined && (
                <span className="ml-2 text-sm">({data.pagination.total})</span>
              )}
            </button>
          ))}
        </div>
      </div>

      {/* Gallery */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {isLoading ? (
          Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="bg-white rounded-lg shadow animate-pulse">
              <div className="w-full h-48 bg-gray-300 rounded-t-lg"></div>
              <div className="p-4 space-y-2">
                <div className="h-4 bg-gray-300 rounded w-3/4"></div>
                <div className="h-4 bg-gray-300 rounded w-1/2"></div>
              </div>
            </div>
          ))
        ) : data?.data?.length === 0 ? (
          <div className="col-span-full text-center py-12">
            <Filter size={48} className="mx-auto text-gray-400 mb-4" />
            <p className="text-gray-600">Aucune image trouvée</p>
          </div>
        ) : (
          data?.data?.map((image: any) => (
            <Link
              key={image.id}
              href={`/admin/images/${image.id}`}
              className="group bg-white rounded-lg shadow overflow-hidden hover:shadow-lg transition-shadow"
            >
              {/* Image */}
              <div className="relative w-full h-48 bg-gray-100 overflow-hidden">
                <img
                  src={image.image_url}
                  alt="Product"
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                  onError={(e) => {
                    ;(e.target as HTMLImageElement).src = '/placeholder.png'
                  }}
                />
                {/* AI Scores Overlay */}
                <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors flex items-center justify-center opacity-0 group-hover:opacity-100">
                  <Eye className="text-white" size={32} />
                </div>
              </div>

              {/* Info */}
              <div className="p-4 space-y-3">
                {/* Status */}
                <div>
                  <span
                    className={`inline-block px-3 py-1 rounded-full text-xs font-medium ${statusConfig[image.status].bg} ${statusConfig[image.status].text}`}
                  >
                    {statusConfig[image.status].label}
                  </span>
                </div>

                {/* AI Scores */}
                {image.ai_nudity_score !== null && (
                  <div className="text-xs space-y-1">
                    <div className="flex justify-between text-gray-600">
                      <span>Nudité:</span>
                      <span className="font-medium">{(image.ai_nudity_score * 100).toFixed(0)}%</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-1.5">
                      <div
                        className={`h-1.5 rounded-full ${
                          image.ai_nudity_score > 0.5 ? 'bg-red-500' : 'bg-green-500'
                        }`}
                        style={{ width: `${image.ai_nudity_score * 100}%` }}
                      ></div>
                    </div>
                  </div>
                )}

                {/* Metadata */}
                <div className="text-xs text-gray-500 pt-2 border-t border-gray-200">
                  <p>Produit: {image.product_id.slice(0, 8)}...</p>
                  <p>
                    {new Date(image.created_at).toLocaleDateString('fr-FR', {
                      day: 'numeric',
                      month: 'short',
                    })}
                  </p>
                </div>

                {/* Quick Actions */}
                <div className="flex gap-2 pt-2">
                  {image.status === 'pending' && (
                    <>
                      <button
                        className="flex-1 flex items-center justify-center gap-1 px-3 py-1.5 bg-green-100 hover:bg-green-200 text-green-700 rounded text-xs font-medium transition-colors"
                        onClick={(e) => {
                          e.preventDefault()
                        }}
                      >
                        <CheckCircle size={14} />
                        Approuver
                      </button>
                      <button
                        className="flex-1 flex items-center justify-center gap-1 px-3 py-1.5 bg-red-100 hover:bg-red-200 text-red-700 rounded text-xs font-medium transition-colors"
                        onClick={(e) => {
                          e.preventDefault()
                        }}
                      >
                        <XCircle size={14} />
                        Rejeter
                      </button>
                    </>
                  )}
                </div>
              </div>
            </Link>
          ))
        )}
      </div>

      {/* Pagination */}
      {data?.pagination && data.pagination.pages > 1 && (
        <div className="flex items-center justify-between bg-white rounded-lg shadow p-4">
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
  )
}
