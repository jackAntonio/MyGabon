-- ============================================
-- ADMIN DASHBOARD TABLES
-- Exécuter ce SQL dans Supabase
-- ============================================

-- 1. TABLE: Dashboard Admins
-- ⚠️ Nommée `dashboard_admins` (et non `admin_users`) pour ne pas collisionner
-- avec la table `admin_users` créée par supabase/migrations/20260623_admin_and_drivers.sql
-- (qui sert un objectif différent : marquer un auth.uid() Supabase comme admin
-- pour les RLS/RPC de l'app Flutter). Les deux tables s'appelaient `admin_users`
-- via CREATE TABLE IF NOT EXISTS : selon l'ordre d'exécution, l'une écrasait
-- silencieusement l'autre.
CREATE TABLE IF NOT EXISTS dashboard_admins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT DEFAULT 'moderator' CHECK (role IN ('super_admin', 'moderator', 'analyst', 'support')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
  two_fa_enabled BOOLEAN DEFAULT FALSE,
  two_fa_secret TEXT,
  last_login TIMESTAMP,
  last_login_ip TEXT,
  failed_login_attempts INT DEFAULT 0,
  locked_until TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. TABLE: Admin Audit Logs
CREATE TABLE IF NOT EXISTS admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID NOT NULL REFERENCES dashboard_admins(id) ON DELETE SET NULL,
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

-- 3. TABLE: Admin Sessions
CREATE TABLE IF NOT EXISTS admin_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID NOT NULL REFERENCES dashboard_admins(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 4. TABLE: Image Moderation Queue
CREATE TABLE IF NOT EXISTS image_moderation (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'flagged', 'under_review')),
  reason_rejected TEXT,

  -- AI Analysis Results
  ai_nudity_score DECIMAL(3,2) DEFAULT 0,
  ai_violence_score DECIMAL(3,2) DEFAULT 0,
  ai_illegal_score DECIMAL(3,2) DEFAULT 0,
  ai_quality_score DECIMAL(3,2) DEFAULT 0,
  ai_recommendation TEXT,
  ai_analysis_at TIMESTAMP,

  -- Review Info
  reviewed_by UUID REFERENCES dashboard_admins(id),
  reviewed_at TIMESTAMP,
  review_notes TEXT,

  -- Metadata
  file_size INT,
  image_width INT,
  image_height INT,
  mime_type TEXT,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 5. TABLE: Wallet Adjustments (Audit Trail)
CREATE TABLE IF NOT EXISTS wallet_adjustments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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

-- 6. TABLE: Webhooks
CREATE TABLE IF NOT EXISTS admin_webhooks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  url TEXT NOT NULL,
  events TEXT[] NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  signing_secret TEXT NOT NULL,
  created_by UUID REFERENCES dashboard_admins(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 7. TABLE: Webhook Logs
CREATE TABLE IF NOT EXISTS webhook_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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

-- 8. TABLE: Admin Permissions
CREATE TABLE IF NOT EXISTS admin_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role TEXT NOT NULL UNIQUE,
  permissions JSONB NOT NULL DEFAULT '{
    "users": {"read": true, "create": false, "update": false, "delete": false},
    "images": {"read": true, "approve": false, "reject": false},
    "wallet": {"read": true, "adjust": false},
    "analytics": {"read": true},
    "settings": {"read": false}
  }',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_dashboard_admins_email ON dashboard_admins(email);
CREATE INDEX idx_dashboard_admins_role ON dashboard_admins(role);
CREATE INDEX idx_dashboard_admins_status ON dashboard_admins(status);
CREATE INDEX idx_admin_audit_logs_admin_id ON admin_audit_logs(admin_id);
CREATE INDEX idx_admin_audit_logs_resource ON admin_audit_logs(resource_type, resource_id);
CREATE INDEX idx_admin_audit_logs_created_at ON admin_audit_logs(created_at);
CREATE INDEX idx_image_moderation_status ON image_moderation(status);
CREATE INDEX idx_image_moderation_product_id ON image_moderation(product_id);
CREATE INDEX idx_image_moderation_created_at ON image_moderation(created_at);
CREATE INDEX idx_wallet_adjustments_user_id ON wallet_adjustments(user_id);
CREATE INDEX idx_wallet_adjustments_admin_id ON wallet_adjustments(admin_id);
CREATE INDEX idx_wallet_adjustments_status ON wallet_adjustments(status);
CREATE INDEX idx_webhook_logs_webhook_id ON webhook_logs(webhook_id);
CREATE INDEX idx_webhook_logs_created_at ON webhook_logs(created_at);

-- ============================================
-- DEFAULT PERMISSIONS
-- ============================================

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

-- ============================================
-- CREATE FIRST ADMIN
-- ============================================
-- ⚠️ Aucun compte n'est créé par ce script. Génère ton propre hash bcrypt
-- (coût >= 10) en local, ex. avec Node :
--   node -e "console.log(require('bcryptjs').hashSync(process.argv[1], 10))" 'TonMotDePasseLong'
-- puis exécute manuellement, avec TON email et TON hash :
--   INSERT INTO dashboard_admins (email, password_hash, full_name, role, status)
--   VALUES ('toi@example.com', '<hash généré ci-dessus>', 'Ton Nom', 'super_admin', 'active');
-- Ne committe jamais ce hash ni le mot de passe en clair dans le repo.

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS for all tables
ALTER TABLE dashboard_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE image_moderation ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_webhooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_logs ENABLE ROW LEVEL SECURITY;

-- ⚠️ Volontairement AUCUNE policy SELECT/INSERT/UPDATE/DELETE pour anon/authenticated
-- sur ces tables : RLS "deny by default" une fois activée sans policy. Le backend
-- Next.js (admin/lib/supabase.ts -> supabaseAdmin) utilise exclusivement la clé
-- service_role, qui bypass RLS — ce n'est jamais la clé anon/authenticated qui
-- doit toucher dashboard_admins, admin_audit_logs, image_moderation, etc.
-- (l'ancienne policy "USING (TRUE)" exposait password_hash et two_fa_secret de
-- tous les admins à quiconque possède la clé anon publique : ne pas la rétablir.)

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update updated_at on dashboard_admins
CREATE TRIGGER dashboard_admins_updated_at
  BEFORE UPDATE ON dashboard_admins
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Trigger: Update updated_at on image_moderation
CREATE TRIGGER image_moderation_updated_at
  BEFORE UPDATE ON image_moderation
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Trigger: Update updated_at on wallet_adjustments
CREATE TRIGGER wallet_adjustments_updated_at
  BEFORE UPDATE ON wallet_adjustments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Function: Log admin actions to audit_logs
CREATE OR REPLACE FUNCTION log_admin_action(
  p_admin_id UUID,
  p_action TEXT,
  p_resource_type TEXT,
  p_resource_id TEXT,
  p_changes JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO admin_audit_logs (admin_id, action, resource_type, resource_id, changes)
  VALUES (p_admin_id, p_action, p_resource_type, p_resource_id, p_changes)
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- DONE!
-- ============================================
-- Toutes les tables sont créées
-- User de test: admin@mygabon.com / admin123
