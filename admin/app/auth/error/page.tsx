'use client'

import { useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { AlertCircle } from 'lucide-react'

export default function AuthErrorPage() {
  const searchParams = useSearchParams()
  const error = searchParams.get('error') || 'Unknown error'

  const errorMessages: Record<string, string> = {
    Callback: 'Erreur lors du callback d\'authentification',
    OAuthSignin: 'Erreur lors de la connexion avec le fournisseur OAuth',
    OAuthCallback: 'Erreur lors du callback OAuth',
    OAuthCreateAccount: 'Impossible de créer un compte avec ce fournisseur',
    EmailCreateAccount: 'Impossible de créer un compte avec cet email',
    Callback: 'Erreur lors du callback d\'authentification',
    EmailSignin: 'Vérifiez votre email pour vous connecter',
    EmailSigninError: 'Email fourni ne peut pas être utilisé pour la connexion',
    CredentialsSignin: 'Échec de la connexion. Vérifiez vos identifiants.',
    SessionCallback: 'Erreur lors de la création de la session',
    JWTCallback: 'Erreur lors de la création du JWT',
    default: 'Une erreur d\'authentification s\'est produite',
  }

  const message = errorMessages[error] || errorMessages['default']

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary via-primary/80 to-primary/60 px-4">
      <div className="w-full max-w-md">
        <div className="bg-white rounded-2xl shadow-xl p-8">
          <div className="flex justify-center mb-6">
            <div className="p-4 bg-red-100 rounded-full">
              <AlertCircle size={32} className="text-red-600" />
            </div>
          </div>

          <h1 className="text-2xl font-bold text-gray-900 text-center mb-4">
            Erreur d'Authentification
          </h1>

          <p className="text-gray-600 text-center mb-6">{message}</p>

          <div className="p-4 bg-red-50 border border-red-200 rounded-lg mb-6">
            <p className="text-xs text-red-700">
              <span className="font-semibold">Code d'erreur:</span> {error}
            </p>
          </div>

          <div className="flex gap-3">
            <Link
              href="/auth/login"
              className="flex-1 px-4 py-2 bg-primary hover:bg-primary/90 text-white rounded-lg transition-colors font-medium text-center"
            >
              Retourner à la connexion
            </Link>
          </div>

          <p className="text-center text-gray-600 text-sm mt-4">
            Si le problème persiste, contactez l'assistance.
          </p>
        </div>
      </div>
    </div>
  )
}
