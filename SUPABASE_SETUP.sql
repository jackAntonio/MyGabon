-- ============================================================
-- GABON CONNECT - SUPABASE SETUP
-- Copier-collez TOUT ce code dans Supabase SQL Editor
-- ============================================================

-- ✅ CREATE USERS TABLE
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone_number TEXT,
  avatar_url TEXT,
  bio TEXT,
  verified BOOLEAN DEFAULT false,
  rating FLOAT DEFAULT 0,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- ✅ CREATE SERVICES TABLE
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

-- ✅ CREATE PRODUCTS TABLE
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2),
  category TEXT,
  condition TEXT DEFAULT 'Bon état',
  location TEXT DEFAULT 'Libreville',
  quantity INT DEFAULT 1,
  image_url TEXT,
  published BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- ✅ CREATE TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID NOT NULL REFERENCES users(id),
  seller_id UUID NOT NULL REFERENCES users(id),
  product_id UUID NOT NULL REFERENCES products(id),
  gross_amount DECIMAL(10, 2) NOT NULL,
  visible_fee DECIMAL(10, 2) NOT NULL,
  actual_fee DECIMAL(10, 2) NOT NULL,
  net_to_seller DECIMAL(10, 2) NOT NULL,
  payment_method TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  transaction_reference TEXT,
  created_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP
);

-- ✅ CREATE USER WALLETS TABLE
CREATE TABLE IF NOT EXISTS user_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id),
  balance DECIMAL(10, 2) DEFAULT 0,
  updated_at TIMESTAMP DEFAULT now()
);

-- ✅ ENABLE ROW LEVEL SECURITY
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_wallets ENABLE ROW LEVEL SECURITY;

-- ✅ POLICIES D'ACCÈS
-- users / transactions / user_wallets : données privées, accès restreint au propriétaire.
-- services / products : catalogue public, lecture ouverte à tous.
CREATE POLICY "Users can read own row" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Public read" ON services FOR SELECT USING (true);
CREATE POLICY "Public read" ON products FOR SELECT USING (true);
CREATE POLICY "Buyer or seller can read own transactions" ON transactions
  FOR SELECT USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

CREATE POLICY "Users can read own wallet" ON user_wallets FOR SELECT USING (auth.uid() = user_id);
-- ⚠️ Volontairement aucune policy INSERT/UPDATE côté client sur user_wallets :
-- les crédits/débits doivent passer par une fonction serveur (RPC SECURITY DEFINER ou
-- Edge Function) qui valide la transaction réelle avant de toucher au solde, jamais
-- un UPDATE direct piloté par un montant fourni par le client (sinon un utilisateur
-- pourrait créditer son propre solde à volonté via l'API REST Supabase).

-- ============================================================
-- INSERT GABON DEMO DATA (8 USERS)
-- ============================================================

INSERT INTO users (id, email, full_name, phone_number, bio, verified, rating) VALUES
  (gen_random_uuid(), 'jean.mbadinga@gmail.com', 'Jean Mbadinga', '+241612345678', 'Électricien professionnel', true, 4.8),
  (gen_random_uuid(), 'marie.ondoua@gmail.com', 'Marie Ondoua', '+241614567890', 'Experte en nettoyage', true, 4.9),
  (gen_random_uuid(), 'claude.nkomo@gmail.com', 'Claude Nkomo', '+241616789012', 'Réparateur informatique', true, 4.7),
  (gen_random_uuid(), 'sophie.ivie@gmail.com', 'Sophie Ivié', '+241618901234', 'Vendeuse de mode', true, 4.8),
  (gen_random_uuid(), 'pierre.mboumbou@gmail.com', 'Pierre Mboumbou', '+241610234567', 'Menuisier', true, 4.6),
  (gen_random_uuid(), 'fatima.traore@gmail.com', 'Fatima Traoré', '+241612345670', 'Coiffure luxe', true, 4.9),
  (gen_random_uuid(), 'jean.client@gmail.com', 'Jean Client', '+241620000000', 'Acheteur', false, 0),
  (gen_random_uuid(), 'alice.dupont@gmail.com', 'Alice Dupont', '+241621111111', 'Acheteuse', false, 0);

-- ============================================================
-- INSERT SERVICES (9 SERVICES)
-- ============================================================

INSERT INTO services (provider_id, title, description, price, category, rating) VALUES
  ((SELECT id FROM users WHERE email='jean.mbadinga@gmail.com'), 'Installation électrique', 'Installation électrique professionnelle', 50000, 'Électricité', 4.8),
  ((SELECT id FROM users WHERE email='jean.mbadinga@gmail.com'), 'Réparation électrique', 'Réparation rapide et efficace', 25000, 'Électricité', 4.9),
  ((SELECT id FROM users WHERE email='marie.ondoua@gmail.com'), 'Nettoyage maison', 'Nettoyage résidentiel complet', 30000, 'Nettoyage', 4.9),
  ((SELECT id FROM users WHERE email='marie.ondoua@gmail.com'), 'Nettoyage bureau', 'Nettoyage professionnel de bureau', 45000, 'Nettoyage', 4.7),
  ((SELECT id FROM users WHERE email='claude.nkomo@gmail.com'), 'Réparation ordinateur', 'Diagnostic et réparation informatique', 25000, 'Informatique', 4.7),
  ((SELECT id FROM users WHERE email='claude.nkomo@gmail.com'), 'Installation réseau', 'Installation réseau professionnelle', 75000, 'Informatique', 4.8),
  ((SELECT id FROM users WHERE email='pierre.mboumbou@gmail.com'), 'Menuiserie custom', 'Menuiserie sur mesure de qualité', 60000, 'Menuiserie', 4.6),
  ((SELECT id FROM users WHERE email='fatima.traore@gmail.com'), 'Coiffure femme', 'Coiffure tendance et stylisme', 15000, 'Beauté', 4.9),
  ((SELECT id FROM users WHERE email='fatima.traore@gmail.com'), 'Coiffure homme', 'Coupe et entretien barbe', 8000, 'Beauté', 4.8);

-- ============================================================
-- INSERT PRODUCTS (5 PRODUCTS)
-- ============================================================

INSERT INTO products (seller_id, title, description, price, category, condition, location) VALUES
  ((SELECT id FROM users WHERE email='sophie.ivie@gmail.com'), 'iPhone 14 Pro', 'Téléphone dernière génération en excellent état', 850000, 'Électronique', 'Neuf', 'Libreville'),
  ((SELECT id FROM users WHERE email='claude.nkomo@gmail.com'), 'Laptop Gaming', 'Ordinateur gaming haute performance RTX 4080', 1200000, 'Électronique', 'Bon état', 'Port-Gentil'),
  ((SELECT id FROM users WHERE email='sophie.ivie@gmail.com'), 'Vêtements collection été', 'Collection été exclusive marque connue', 45000, 'Vêtements', 'Neuf', 'Libreville'),
  ((SELECT id FROM users WHERE email='sophie.ivie@gmail.com'), 'Chaussures Nike', 'Baskets Nike authentiques dernière collection', 75000, 'Vêtements', 'Neuf', 'Libreville'),
  ((SELECT id FROM users WHERE email='sophie.ivie@gmail.com'), 'Sacs à main cuir', 'Sacs cuir véritable de luxe', 120000, 'Accessoires', 'Bon état', 'Libreville');

-- ============================================================
-- ✅ SETUP COMPLETE!
-- ============================================================
-- Tables created with 8 users, 9 services, 5 products
-- All data is ready for the app to use!
-- ============================================================
