'use client'

import { useSession } from 'next-auth/react'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'
import { roleHasPermission } from '@/lib/permissions'

export function useAuthProtected() {
  const { data: session, status } = useSession()
  const router = useRouter()

  useEffect(() => {
    if (status === 'unauthenticated') {
      router.push('/auth/login')
    }
  }, [status, router])

  return { session, status, isLoading: status === 'loading' }
}

export function useAdminRole() {
  const { data: session } = useSession()
  return (session?.user as any)?.role || null
}

// ⚠️ Décoratif uniquement (masquer un bouton) : la même règle est revérifiée
// côté serveur dans chaque route API via lib/apiAuth.ts#requirePermission,
// qui seul fait foi pour l'autorisation réelle.
export function useCanAccess(permission: string) {
  const { data: session } = useSession()
  const userRole = (session?.user as any)?.role
  return roleHasPermission(userRole, permission)
}
