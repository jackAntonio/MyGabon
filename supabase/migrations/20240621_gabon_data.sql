-- GabonConnect - Schema + Real Demo Data
-- Date: 2024-06-21

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone_number TEXT,
  avatar_url TEXT,
  bio TEXT,
  verified BOOLEAN DEFAULT false,
  verified_at TIMESTAMP,
  last_login_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Services table
CREATE TABLE IF NOT EXISTS services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2),
  category TEXT,
  rating FLOAT DEFAULT 0,
  reviews_count INT DEFAULT 0,
  image_url TEXT,
  published BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2),
  category TEXT,
  quantity INT DEFAULT 1,
  image_url TEXT,
  published BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES users(id),
  receiver_id UUID NOT NULL REFERENCES users(id),
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

-- Audit logs table
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  action TEXT NOT NULL,
  resource TEXT,
  resource_id TEXT,
  details JSONB,
  ip_address INET,
  user_agent TEXT,
  status TEXT DEFAULT 'success',
  error_message TEXT,
  created_at TIMESTAMP DEFAULT now()
);

-- Reviews table
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reviewer_id UUID NOT NULL REFERENCES users(id),
  reviewee_id UUID NOT NULL REFERENCES users(id),
  rating INT CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  tags TEXT[],
  recommends BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Insert Demo Users (REAL DATA FOR GABON)
INSERT INTO users (email, full_name, phone_number, avatar_url, bio, verified) VALUES
  ('jean.mbadinga@gmail.com', 'Jean Mbadinga', '+241612345678', 'https://i.pravatar.cc/150?img=1', 'Électricien professionnel à Libreville', true),
  ('marie.ondoua@gmail.com', 'Marie Ondoua', '+241614567890', 'https://i.pravatar.cc/150?img=2', 'Experte en nettoyage résidentiel', true),
  ('claude.nkomo@gmail.com', 'Claude Nkomo', '+241616789012', 'https://i.pravatar.cc/150?img=3', 'Réparateur informatique certifié', true),
  ('sophie.ivie@gmail.com', 'Sophie Ivié', '+241618901234', 'https://i.pravatar.cc/150?img=4', 'Vendeuse de vêtements branché', true),
  ('pierre.mboumbou@gmail.com', 'Pierre Mboumbou', '+241610234567', 'https://i.pravatar.cc/150?img=5', 'Menuisier & ébéniste', true),
  ('fatima.traore@gmail.com', 'Fatima Traoré', '+241612345670', 'https://i.pravatar.cc/150?img=6', 'Coiffure luxe', true),
  ('jean.client@gmail.com', 'Jean Client', '+241613456789', 'https://i.pravatar.cc/150?img=7', 'Chercheur de services', false),
  ('client.alice@gmail.com', 'Alice Dupont', '+241614567891', 'https://i.pravatar.cc/150?img=8', 'Acheteuse active', false);

-- Insert Demo Services (REAL GABON SERVICES)
INSERT INTO services (provider_id, title, description, price, category, rating, reviews_count, published) VALUES
  ((SELECT id FROM users WHERE email = 'jean.mbadinga@gmail.com'), 'Installation électrique', 'Installation complète de circuits électriques, tableau, etc.', 50000, 'électricité', 4.8, 142, true),
  ((SELECT id FROM users WHERE email = 'jean.mbadinga@gmail.com'), 'Réparation électrique', 'Dépannage électrique urgent - 24h/24', 25000, 'électricité', 4.9, 89, true),
  ((SELECT id FROM users WHERE email = 'marie.ondoua@gmail.com'), 'Nettoyage maison', 'Nettoyage complet résidentiel', 30000, 'nettoyage', 4.9, 156, true),
  ((SELECT id FROM users WHERE email = 'marie.ondoua@gmail.com'), 'Nettoyage bureau', 'Nettoyage et maintenance bureaux', 45000, 'nettoyage', 4.7, 72, true),
  ((SELECT id FROM users WHERE email = 'claude.nkomo@gmail.com'), 'Réparation ordinateur', 'Diagnostic, logiciels, hardware', 25000, 'informatique', 4.7, 56, true),
  ((SELECT id FROM users WHERE email = 'claude.nkomo@gmail.com'), 'Installation réseau', 'Mise en place WiFi, câblage réseau', 75000, 'informatique', 4.8, 34, true),
  ((SELECT id FROM users WHERE email = 'pierre.mboumbou@gmail.com'), 'Menuiserie', 'Meubles, portes, escaliers custom', 60000, 'menuiserie', 4.6, 43, true),
  ((SELECT id FROM users WHERE email = 'fatima.traore@gmail.com'), 'Coiffure femme', 'Coupe, coloration, tissage', 15000, 'beauté', 4.9, 234, true),
  ((SELECT id FROM users WHERE email = 'fatima.traore@gmail.com'), 'Coiffure homme', 'Coupe tendance, barbe', 8000, 'beauté', 4.8, 167, true);

-- Insert Demo Products (MARKETPLACE)
INSERT INTO products (seller_id, title, description, price, category, quantity, published) VALUES
  ((SELECT id FROM users WHERE email = 'sophie.ivie@gmail.com'), 'iPhone 14 Pro', 'Excellent état, complet avec accessoires', 850000, 'électronique', 1, true),
  ((SELECT id FROM users WHERE email = 'sophie.ivie@gmail.com'), 'Vetements femme collection été', 'Robe, chemise, short tendance', 45000, 'mode', 5, true),
  ((SELECT id FROM users WHERE email = 'pierre.mboumbou@gmail.com'), 'Mobilier bureau', 'Bureau, chaise, étagère occasion bon état', 150000, 'mobilier', 3, true),
  ((SELECT id FROM users WHERE email = 'jean.client@gmail.com'), 'Chaussures Nike', 'Baskets neuves, taille 42', 75000, 'mode', 2, true),
  ((SELECT id FROM users WHERE email = 'client.alice@gmail.com'), 'Laptop gaming', 'RTX 3060, i7, 16GB RAM, comme neuf', 1200000, 'électronique', 1, true),
  ((SELECT id FROM users WHERE email = 'sophie.ivie@gmail.com'), 'Sacs à main', 'Cuir véritable, designs italiens', 120000, 'mode', 4, true),
  ((SELECT id FROM users WHERE email = 'pierre.mboumbou@gmail.com'), 'Canapé', 'Cuir, 3 places, très bon état', 300000, 'mobilier', 1, true);

-- Insert Demo Messages (CHAT)
INSERT INTO messages (sender_id, receiver_id, content, read) VALUES
  ((SELECT id FROM users WHERE email = 'jean.client@gmail.com'),
   (SELECT id FROM users WHERE email = 'jean.mbadinga@gmail.com'),
   'Bonjour, je besoin d''une réparation électrique urgent. Pouvez-vous venir demain?',
   false),

  ((SELECT id FROM users WHERE email = 'jean.mbadinga@gmail.com'),
   (SELECT id FROM users WHERE email = 'jean.client@gmail.com'),
   'Oui, bien sûr! Je peux venir entre 10h et 12h demain. C''est pour quel problème?',
   true),

  ((SELECT id FROM users WHERE email = 'client.alice@gmail.com'),
   (SELECT id FROM users WHERE email = 'sophie.ivie@gmail.com'),
   'L''iPhone est encore disponible? Quel est votre dernier prix?',
   false),

  ((SELECT id FROM users WHERE email = 'sophie.ivie@gmail.com'),
   (SELECT id FROM users WHERE email = 'client.alice@gmail.com'),
   'Oui! Prix ferme 850k. Je peux vous le montrer ce weekend?',
   true);

-- Insert Demo Reviews (RATINGS)
INSERT INTO reviews (reviewer_id, reviewee_id, rating, comment, tags, recommends) VALUES
  ((SELECT id FROM users WHERE email = 'jean.client@gmail.com'),
   (SELECT id FROM users WHERE email = 'jean.mbadinga@gmail.com'),
   5,
   'Excellent travail! Très professionnel et rapide. Je recommande vivement!',
   ARRAY['professionnel', 'rapide', 'fiable'],
   true),

  ((SELECT id FROM users WHERE email = 'client.alice@gmail.com'),
   (SELECT id FROM users WHERE email = 'marie.ondoua@gmail.com'),
   5,
   'Nettoyage impeccable! Ma maison brille comme neuve. Mercii!',
   ARRAY['excellent', 'détail', 'courtois'],
   true),

  ((SELECT id FROM users WHERE email = 'jean.client@gmail.com'),
   (SELECT id FROM users WHERE email = 'claude.nkomo@gmail.com'),
   4,
   'Bon diagnostic. Dommage qu''il n''avait pas la pièce pour réparation directe.',
   ARRAY['honnête', 'compétent'],
   true);

-- Insert Demo Audit Logs (PHASE 2)
INSERT INTO audit_logs (user_id, action, resource, status, details) VALUES
  ((SELECT id FROM users WHERE email = 'jean.client@gmail.com'),
   'login',
   'auth',
   'success',
   jsonb_build_object('email', 'jean.client@gmail.com', 'method', 'email_password')),

  ((SELECT id FROM users WHERE email = 'jean.mbadinga@gmail.com'),
   'service_created',
   'services',
   'success',
   jsonb_build_object('service', 'Installation électrique', 'category', 'électricité')),

  ((SELECT id FROM users WHERE email = 'jean.client@gmail.com'),
   'message_sent',
   'messages',
   'success',
   jsonb_build_object('to', 'jean.mbadinga@gmail.com')),

  ((SELECT id FROM users WHERE email = 'client.alice@gmail.com'),
   'phone_verified',
   'users',
   'success',
   jsonb_build_object('phone', '****7891', 'method', 'otp_sms')),

  ((SELECT id FROM users WHERE email = 'sophie.ivie@gmail.com'),
   'product_listed',
   'products',
   'success',
   jsonb_build_object('product', 'iPhone 14 Pro', 'price', 850000));

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_verified ON users(verified);
CREATE INDEX IF NOT EXISTS idx_services_provider ON services(provider_id);
CREATE INDEX IF NOT EXISTS idx_services_category ON services(category);
CREATE INDEX IF NOT EXISTS idx_services_rating ON services(rating DESC);
CREATE INDEX IF NOT EXISTS idx_products_seller ON products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer ON reviews(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewee ON reviews(reviewee_id);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- ⚠️ users / messages / audit_logs contiennent des données privées (email, téléphone,
-- contenu de chat, journaux d'audit) : accès restreint au propriétaire.
-- services / products / reviews restent en lecture publique (catalogue marketplace).
CREATE POLICY "Users can read own row" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own row" ON users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Allow public select" ON services FOR SELECT USING (true);
CREATE POLICY "Providers manage own services" ON services FOR ALL USING (auth.uid() = provider_id);

CREATE POLICY "Allow public select" ON products FOR SELECT USING (true);
CREATE POLICY "Sellers manage own products" ON products FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Participants can read own messages" ON messages
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Users can send messages as themselves" ON messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can read own audit logs" ON audit_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own audit logs" ON audit_logs FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow public select" ON reviews FOR SELECT USING (true);
CREATE POLICY "Reviewers can create reviews" ON reviews
  FOR INSERT WITH CHECK (auth.uid() = reviewer_id);
