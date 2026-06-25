// Matrice de permissions partagée client/serveur. Le client (useAuth.ts)
// l'utilise pour masquer des boutons ; les routes API (apiAuth.ts) l'utilisent
// pour autoriser ou refuser l'action — c'est cette seconde vérification qui
// fait foi, car un appel direct à l'API (curl, fetch hors UI) ne passe jamais
// par le rendu React.
export type AdminRole = 'super_admin' | 'moderator' | 'analyst' | 'support'

export const ROLE_PERMISSIONS: Record<AdminRole, string[]> = {
  super_admin: ['all'],
  moderator: [
    'users:read',
    'users:create',
    'users:update',
    'images:read',
    'images:approve',
    'images:reject',
  ],
  analyst: ['analytics:read', 'users:read'],
  support: ['users:read', 'users:update'],
}

export function roleHasPermission(role: string | undefined | null, permission: string): boolean {
  const allowed = ROLE_PERMISSIONS[role as AdminRole] || []
  return allowed.includes('all') || allowed.includes(permission)
}
