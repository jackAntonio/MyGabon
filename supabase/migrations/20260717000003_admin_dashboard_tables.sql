-- ============================================================
-- Tables du dashboard admin Next.js (admin/SQL_SETUP.sql), déployées sur le
-- projet actif. Adapté : gen_random_uuid() au lieu de uuid_generate_v4()
-- (pas d'extension uuid-ossp requise), index IF NOT EXISTS (rejouable).
--
-- Système d'admin SÉPARÉ de admin_users (admin in-app Flutter) : ici c'est
-- l'auth du panneau web (email + bcrypt + 2FA optionnelle), lue uniquement
-- par le backend Next.js via la clé service_role.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Admins du dashboard web
CREATE TABLE IF NOT EXISTS dashboard_admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT DEFAULT 'moderator' CHECK (role IN ('super_admin', 'moderator', 'analyst', 'support')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
  two_fa_enabled BOOLEAN DEFAULT FALSE,
  two_fa_secret BYTEA,
  last_login TIMESTAMP,
  last_login_ip TEXT,
  failed_login_attempts INT DEFAULT 0,
  locked_until TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Journal d'audit admin
CREATE TABLE IF NOT EXISTS admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID REFERENCES dashboard_admins(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  resource_type TEXT,
  resource_id TEXT,
  changes JSONB,
  ip_address TEXT,
  user_agent TEXT,
  status TEXT DEFAULT 'success',
  error_message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 3. Sessions admin
CREATE TABLE IF NOT EXISTS admin_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES dashboard_admins(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 4. File de modération d'images
CREATE TABLE IF NOT EXISTS image_moderation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'flagged', 'under_review')),
  reason_rejected TEXT,
  ai_nudity_score DECIMAL(3,2) DEFAULT 0,
  ai_violence_score DECIMAL(3,2) DEFAULT 0,
  ai_illegal_score DECIMAL(3,2) DEFAULT 0,
  ai_quality_score DECIMAL(3,2) DEFAULT 0,
  ai_recommendation TEXT,
  ai_analysis_at TIMESTAMP,
  reviewed_by UUID REFERENCES dashboard_admins(id),
  reviewed_at TIMESTAMP,
  review_notes TEXT,
  file_size INT,
  image_width INT,
  image_height INT,
  mime_type TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 5. Ajustements de wallet (piste d'audit)
CREATE TABLE IF NOT EXISTS wallet_adjustments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  admin_id UUID REFERENCES dashboard_admins(id),
  amount DECIMAL(15,2) NOT NULL,
  reason TEXT NOT NULL CHECK (reason IN ('correction', 'refund', 'bonus', 'penalty', 'manual_adjustment')),
  notes TEXT,
  previous_balance DECIMAL(15,2),
  new_balance DECIMAL(15,2),
  requires_approval BOOLEAN DEFAULT FALSE,
  approved_by UUID REFERENCES dashboard_admins(id),
  approved_at TIMESTAMP,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 6. Webhooks
CREATE TABLE IF NOT EXISTS admin_webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  url TEXT NOT NULL,
  events TEXT[] NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  signing_secret TEXT NOT NULL,
  created_by UUID REFERENCES dashboard_admins(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 7. Logs de webhooks
CREATE TABLE IF NOT EXISTS webhook_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  webhook_id UUID REFERENCES admin_webhooks(id) ON DELETE CASCADE,
  event TEXT NOT NULL,
  payload JSONB,
  response_status INT,
  response_body TEXT,
  retries INT DEFAULT 0,
  last_retry_at TIMESTAMP,
  success BOOLEAN,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 8. Permissions par rôle
CREATE TABLE IF NOT EXISTS admin_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role TEXT NOT NULL UNIQUE,
  permissions JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_dashboard_admins_email ON dashboard_admins(email);
CREATE INDEX IF NOT EXISTS idx_dashboard_admins_role ON dashboard_admins(role);
CREATE INDEX IF NOT EXISTS idx_dashboard_admins_status ON dashboard_admins(status);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_admin_id ON admin_audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_resource ON admin_audit_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_created_at ON admin_audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_image_moderation_status ON image_moderation(status);
CREATE INDEX IF NOT EXISTS idx_image_moderation_product_id ON image_moderation(product_id);
CREATE INDEX IF NOT EXISTS idx_image_moderation_created_at ON image_moderation(created_at);
CREATE INDEX IF NOT EXISTS idx_wallet_adjustments_user_id ON wallet_adjustments(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_adjustments_admin_id ON wallet_adjustments(admin_id);
CREATE INDEX IF NOT EXISTS idx_wallet_adjustments_status ON wallet_adjustments(status);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_webhook_id ON webhook_logs(webhook_id);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_created_at ON webhook_logs(created_at);

-- Permissions par défaut
INSERT INTO admin_permissions (role, permissions) VALUES
('super_admin', '{
  "users": {"read": true, "create": true, "update": true, "delete": true},
  "images": {"read": true, "approve": true, "reject": true, "analyze": true},
  "wallet": {"read": true, "adjust": true, "approve": true},
  "analytics": {"read": true, "export": true},
  "webhooks": {"read": true, "create": true, "edit": true, "delete": true},
  "settings": {"read": true, "edit": true},
  "admin": {"create": true, "edit": true, "delete": true}
}'),
('moderator', '{
  "users": {"read": true, "create": true, "update": true, "delete": false},
  "images": {"read": true, "approve": true, "reject": true, "analyze": true},
  "wallet": {"read": true, "adjust": true, "approve": false},
  "analytics": {"read": true},
  "webhooks": {"read": true},
  "settings": {"read": false}
}'),
('analyst', '{
  "users": {"read": true},
  "images": {"read": true},
  "wallet": {"read": true},
  "analytics": {"read": true, "export": true},
  "webhooks": {"read": false},
  "settings": {"read": false}
}'),
('support', '{
  "users": {"read": true, "update": true},
  "images": {"read": true},
  "wallet": {"read": true},
  "analytics": {"read": false},
  "webhooks": {"read": false},
  "settings": {"read": false}
}')
ON CONFLICT (role) DO NOTHING;

-- RLS : deny by default, aucune policy (seul service_role, qui bypass RLS,
-- accède à ces tables).
ALTER TABLE dashboard_admins   ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_logs   ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_sessions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE image_moderation   ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_webhooks     ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_logs       ENABLE ROW LEVEL SECURITY;

-- updated_at auto
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS dashboard_admins_updated_at ON dashboard_admins;
CREATE TRIGGER dashboard_admins_updated_at
  BEFORE UPDATE ON dashboard_admins
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS image_moderation_updated_at ON image_moderation;
CREATE TRIGGER image_moderation_updated_at
  BEFORE UPDATE ON image_moderation
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS wallet_adjustments_updated_at ON wallet_adjustments;
CREATE TRIGGER wallet_adjustments_updated_at
  BEFORE UPDATE ON wallet_adjustments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Fonctions TOTP (2FA) : présentes pour compat, non utilisées tant que la
-- clé Vault 'totp_encryption_key' n'existe pas sur ce projet (2FA désactivée).
-- Droits d'exécution restreints à service_role dans la migration suivante
-- (20260717000004_harden_admin_dashboard_functions.sql).
CREATE OR REPLACE FUNCTION encrypt_totp_secret(p_secret TEXT)
RETURNS BYTEA
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_key TEXT;
BEGIN
  SELECT decrypted_secret INTO v_key FROM vault.decrypted_secrets WHERE name = 'totp_encryption_key';
  IF v_key IS NULL THEN
    RAISE EXCEPTION 'totp_encryption_key non configurée dans Vault';
  END IF;
  RETURN pgp_sym_encrypt(p_secret, v_key);
END;
$$;

CREATE OR REPLACE FUNCTION get_decrypted_totp_secret(p_admin_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_key TEXT;
  v_encrypted BYTEA;
BEGIN
  SELECT decrypted_secret INTO v_key FROM vault.decrypted_secrets WHERE name = 'totp_encryption_key';
  SELECT two_fa_secret INTO v_encrypted FROM dashboard_admins WHERE id = p_admin_id;
  IF v_key IS NULL OR v_encrypted IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN pgp_sym_decrypt(v_encrypted, v_key);
END;
$$;

-- ⚠️ Le compte super_admin initial (dashboard_admins) n'est PAS versionné ici
-- (email + hash bcrypt = secret) : à insérer manuellement via SQL editor,
-- comme pour le seed admin_users (cf. 20260623000000_admin_and_drivers.sql).
