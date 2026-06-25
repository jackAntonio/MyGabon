import NextAuth, { type NextAuthOptions } from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'
import { validateAdminLogin, logAdminAction } from '@/lib/auth'

export const authOptions: NextAuthOptions = {
  providers: [
    CredentialsProvider({
      name: 'Credentials',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' },
      },
      async authorize(credentials, req) {
        if (!credentials?.email || !credentials?.password) {
          return null
        }

        const result = await validateAdminLogin(credentials.email, credentials.password)

        if (result.error || !result.admin) {
          return null
        }

        const admin = result.admin

        // Log successful login
        await logAdminAction(
          admin.id,
          'login_success',
          'admin_users',
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

export default NextAuth(authOptions)
