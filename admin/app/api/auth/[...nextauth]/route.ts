import NextAuth from 'next-auth'
import { authOptions } from '@/lib/authOptions'

// ⚠️ Un route handler de l'App Router ne peut exporter que des méthodes HTTP
// (GET, POST...) — d'où authOptions déplacé dans lib/authOptions.ts plutôt
// que ré-exporté ici comme dans l'ancien fichier app/api/auth/[...nextauth].ts
// (qui, sans dossier /route.ts, n'était d'ailleurs jamais servi par Next.js :
// /api/auth/csrf répondait 404, l'authentification admin était inopérante).
const handler = NextAuth(authOptions)

export { handler as GET, handler as POST }
