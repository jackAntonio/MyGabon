'use client'

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

export interface ModeratedImage {
  id: string
  product_id: string
  image_url: string
  status: 'pending' | 'approved' | 'rejected' | 'flagged' | 'under_review'
  reason_rejected?: string
  ai_nudity_score: number
  ai_violence_score: number
  ai_illegal_score: number
  ai_quality_score: number
  ai_recommendation?: string
  reviewed_by?: string
  reviewed_at?: string
  created_at: string
}

export function useImageQueue(status = 'pending', page = 1) {
  return useQuery({
    queryKey: ['image-queue', status, page],
    queryFn: async () => {
      const res = await fetch(`/api/images?status=${status}&page=${page}`)
      if (!res.ok) throw new Error('Failed to fetch images')
      return res.json()
    },
  })
}

export function useImageDetails(imageId: string) {
  return useQuery({
    queryKey: ['image', imageId],
    queryFn: async () => {
      const res = await fetch(`/api/images/${imageId}`)
      if (!res.ok) throw new Error('Failed to fetch image')
      return res.json()
    },
    enabled: !!imageId,
  })
}

export function useApproveImage() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ imageId, notes }: { imageId: string; notes?: string }) => {
      const res = await fetch(`/api/images/${imageId}/approve`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ notes }),
      })
      if (!res.ok) throw new Error('Failed to approve image')
      return res.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['image-queue'] })
      queryClient.invalidateQueries({ queryKey: ['image'] })
    },
  })
}

export function useRejectImage() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ imageId, reason, notes }: { imageId: string; reason: string; notes?: string }) => {
      const res = await fetch(`/api/images/${imageId}/reject`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reason, notes }),
      })
      if (!res.ok) throw new Error('Failed to reject image')
      return res.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['image-queue'] })
      queryClient.invalidateQueries({ queryKey: ['image'] })
    },
  })
}

export function useAnalyzeImage() {
  return useMutation({
    mutationFn: async (imageUrl: string) => {
      const res = await fetch('/api/images/analyze', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ imageUrl }),
      })
      if (!res.ok) throw new Error('Failed to analyze image')
      return res.json()
    },
  })
}
