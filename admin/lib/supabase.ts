import 'server-only'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

// ⚠️ import 'server-only' fait échouer le build si ce module est jamais
// importé depuis un composant client — supabaseAdmin (service_role) ne doit
// exister que côté serveur (route handlers / NextAuth), jamais dans un bundle
// envoyé au navigateur.

// Client-side Supabase client
export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Server-side Supabase client (with service role)
export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)

export type Database = {
  public: {
    Tables: {
      dashboard_admins: {
        Row: {
          id: string
          email: string
          password_hash: string
          full_name: string
          role: string
          status: string
          two_fa_enabled: boolean
          two_fa_secret: string | null
          last_login: string | null
          last_login_ip: string | null
          failed_login_attempts: number
          locked_until: string | null
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['dashboard_admins']['Row'], 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Database['public']['Tables']['dashboard_admins']['Insert']>
      }
      image_moderation: {
        Row: {
          id: string
          product_id: string | null
          image_url: string
          status: string
          reason_rejected: string | null
          ai_nudity_score: number
          ai_violence_score: number
          ai_illegal_score: number
          ai_quality_score: number
          ai_recommendation: string | null
          ai_analysis_at: string | null
          reviewed_by: string | null
          reviewed_at: string | null
          review_notes: string | null
          file_size: number | null
          image_width: number | null
          image_height: number | null
          mime_type: string | null
          created_at: string
          updated_at: string
        }
      }
      wallet_adjustments: {
        Row: {
          id: string
          user_id: string
          admin_id: string | null
          amount: number
          reason: string
          notes: string | null
          previous_balance: number | null
          new_balance: number | null
          requires_approval: boolean
          approved_by: string | null
          approved_at: string | null
          status: string
          created_at: string
          updated_at: string
        }
      }
      admin_audit_logs: {
        Row: {
          id: string
          admin_id: string | null
          action: string
          resource_type: string | null
          resource_id: string | null
          changes: any | null
          ip_address: string | null
          user_agent: string | null
          status: string
          error_message: string | null
          created_at: string
        }
      }
      admin_webhooks: {
        Row: {
          id: string
          url: string
          events: string[]
          active: boolean
          signing_secret: string
          created_by: string | null
          created_at: string
          updated_at: string
        }
      }
    }
  }
}
