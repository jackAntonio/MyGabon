import bcrypt from 'bcryptjs'
import { authenticator } from 'otplib'
import { supabaseAdmin } from './supabase'

// ⚠️ Toutes les requêtes de ce fichier utilisent supabaseAdmin (service_role).
// dashboard_admins et admin_audit_logs n'ont plus aucune policy RLS pour
// anon/authenticated (cf. admin/SQL_SETUP.sql) : un client anon ne pourrait
// plus rien y lire ni écrire, ce qui est volontaire.

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 10)
}

// Hash factice utilisé pour égaliser le temps de réponse quand l'email n'existe
// pas (cf. validateAdminLogin) : sans lui, l'absence d'appel bcrypt.compare sur
// ce chemin crée un écart de latence mesurable qui permet d'énumérer les
// emails admin valides.
const DUMMY_HASH = '$2a$10$CwTycUXWue0Thq9StjUM0uJ8L8.dwbpZ6Wer4kxOSHGu1.AAd5wHC'

export async function verifyPassword(
  password: string,
  hash: string
): Promise<boolean> {
  return bcrypt.compare(password, hash)
}

export async function getAdminByEmail(email: string) {
  const { data, error } = await supabaseAdmin
    .from('dashboard_admins')
    .select('*')
    .eq('email', email)
    .single()

  if (error) return null
  return data
}

export async function validateAdminLogin(
  email: string,
  password: string,
  totpCode?: string
) {
  try {
    const admin = await getAdminByEmail(email)

    if (!admin) {
      await verifyPassword(password, DUMMY_HASH)
      return { error: 'Email ou mot de passe incorrect' }
    }

    if (admin.status === 'suspended') {
      return { error: 'Compte suspendu' }
    }

    if (admin.status === 'inactive') {
      return { error: 'Compte inactif' }
    }

    // Check if locked due to failed attempts
    if (admin.locked_until && new Date(admin.locked_until) > new Date()) {
      return { error: 'Compte verrouillé. Réessayez plus tard.' }
    }

    const isPasswordValid = await verifyPassword(password, admin.password_hash)

    if (!isPasswordValid) {
      // Increment failed login attempts
      const failedAttempts = (admin.failed_login_attempts || 0) + 1
      const shouldLock = failedAttempts >= 5

      await supabaseAdmin
        .from('dashboard_admins')
        .update({
          failed_login_attempts: failedAttempts,
          locked_until: shouldLock
            ? new Date(Date.now() + 15 * 60 * 1000).toISOString()
            : null,
        })
        .eq('id', admin.id)

      if (shouldLock) {
        return { error: 'Trop de tentatives. Compte verrouillé 15 minutes.' }
      }

      return { error: 'Email ou mot de passe incorrect' }
    }

    // 2FA : le mot de passe seul ne suffit pas si l'admin a activé le TOTP.
    // two_fa_secret est chiffré au repos (pgcrypto, cf. SQL_SETUP.sql) : on ne
    // le déchiffre que pour cette vérification, via la RPC dédiée, jamais en
    // lisant la colonne brute (admin.two_fa_secret est du BYTEA chiffré).
    if (admin.two_fa_enabled) {
      if (!totpCode) {
        return { error: 'totp_required' }
      }
      const { data: secret, error: secretError } = await supabaseAdmin.rpc(
        'get_decrypted_totp_secret',
        { p_admin_id: admin.id }
      )
      if (secretError || !secret) {
        return { error: 'Erreur lors de la vérification du code' }
      }
      const isTotpValid = authenticator.check(totpCode, secret)
      if (!isTotpValid) {
        return { error: 'Code de vérification invalide' }
      }
    }

    // Reset failed attempts and update last login
    await supabaseAdmin
      .from('dashboard_admins')
      .update({
        failed_login_attempts: 0,
        locked_until: null,
        last_login: new Date().toISOString(),
      })
      .eq('id', admin.id)

    return { admin }
  } catch (error) {
    console.error('Login error:', error)
    return { error: 'Erreur lors du login' }
  }
}

export async function logAdminAction(
  adminId: string,
  action: string,
  resourceType?: string,
  resourceId?: string,
  changes?: any
) {
  try {
    await supabaseAdmin.from('admin_audit_logs').insert({
      admin_id: adminId,
      action,
      resource_type: resourceType,
      resource_id: resourceId,
      changes,
    })
  } catch (error) {
    console.error('Error logging action:', error)
  }
}
