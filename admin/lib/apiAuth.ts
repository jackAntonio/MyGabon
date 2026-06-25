import 'server-only'
import { getServerSession, type Session } from 'next-auth'
import { NextResponse } from 'next/server'
import { authOptions } from '@/lib/authOptions'
import { roleHasPermission } from './permissions'

interface AuthCheck {
  session: Session | null
  response: NextResponse | null
}

// Vérifie la session ET la permission associée au rôle de l'admin connecté.
// À appeler en tout début de chaque route handler avant toute lecture/écriture
// Supabase : la session seule ne suffit pas, un rôle 'analyst' ou 'support'
// ne doit pas pouvoir exécuter une action réservée à 'moderator'/'super_admin'
// simplement en appelant l'API directement (curl/fetch) en dehors de l'UI.
export async function requirePermission(permission: string): Promise<AuthCheck> {
  const session = await getServerSession(authOptions)

  if (!session) {
    return {
      session: null,
      response: NextResponse.json({ error: 'Unauthorized' }, { status: 401 }),
    }
  }

  const role = (session.user as any)?.role
  if (!roleHasPermission(role, permission)) {
    return {
      session,
      response: NextResponse.json({ error: 'Forbidden' }, { status: 403 }),
    }
  }

  return { session, response: null }
}
