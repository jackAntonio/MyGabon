'use client'

import { useSession } from 'next-auth/react'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

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

export function useCanAccess(permission: string) {
  const { data: session } = useSession()
  const userRole = (session?.user as any)?.role

  const permissions: Record<string, string[]> = {
    super_admin: ['all'],
    moderator: ['users:read', 'users:create', 'users:update', 'images:read', 'images:approve', 'images:reject'],
    analyst: ['analytics:read', 'users:read'],
    support: ['users:read', 'users:update'],
  }

  const allowed = permissions[userRole] || []
  return allowed.includes('all') || allowed.includes(permission)
}
