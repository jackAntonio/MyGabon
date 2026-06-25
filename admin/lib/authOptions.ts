import type { NextAuthOptions } from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'
import { validateAdminLogin, logAdminAction } from '@/lib/auth'

export const authOptions: NextAuthOptions = {
  providers: [
    CredentialsProvider({
      name: 'Credentials',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' },
        totpCode: { label: 'Code 2FA', type: 'text' },
      },
      async authorize(credentials, req) {
        if (!credentials?.email || !credentials?.password) {
          return null
        }

        const result = await validateAdminLogin(
          credentials.email,
          credentials.password,
          credentials.totpCode || undefined
        )

        if (result.error || !result.admin) {
          // 'totp_required' est propagé tel quel : la page de login le
          // détecte pour afficher le champ code 2FA sans révéler si
          // l'email/mot de passe étaient corrects.
          throw new Error(result.error || 'Email ou mot de passe incorrect')
        }

        const admin = result.admin

        // Log successful login
        await logAdminAction(
          admin.id,
          'login_success',
          'dashboard_admins',
          admin.id,
          { ip_address: req.headers?.['x-forwarded-for'] || 'unknown' }
        )

        return {
          id: admin.id,
          email: admin.email,
          name: admin.full_name,
          role: admin.role,
        }
      },
    }),
  ],

  pages: {
    signIn: '/auth/login',
    error: '/auth/login',
  },

  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.role = (user as any).role
      }
      return token
    },

    async session({ session, token }) {
      if (session.user) {
        (session.user as any).role = token.role
      }
      return session
    },

    async redirect({ url, baseUrl }) {
      // Redirect to dashboard after login
      if (url.startsWith(baseUrl)) return url
      return `${baseUrl}/admin`
    },
  },

  session: {
    strategy: 'jwt',
    maxAge: 24 * 60 * 60, // 24 hours
  },

  jwt: {
    secret: process.env.NEXTAUTH_SECRET,
  },

  secret: process.env.NEXTAUTH_SECRET,
}
