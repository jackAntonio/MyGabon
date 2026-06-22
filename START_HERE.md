# ⚡ START HERE - Do This Right Now

**Your complete app is ready. Let's make it work in 30 minutes.**

---

## 🎯 30-MINUTE QUICK START

### ⏱️ Step 1: VERIFY (3 minutes)

```bash
# Open PowerShell and run:
flutter --version
flutter doctor
```

**Expected:** Flutter 3.x installed, minimal warnings

---

### ⏱️ Step 2: CREATE SUPABASE PROJECT (5 minutes)

**OPTION A: Cloud (Easiest - Recommended)**
1. Go to https://supabase.com
2. Click "Start your project"
3. Sign up with email/password
4. Create new project
5. Choose region closest to Gabon (Africa/Lagos or Europe/London)
6. Wait 2 minutes for setup

**OPTION B: Local Docker (Skip if you chose A)**
```bash
npm install -g supabase
supabase login
supabase start
# Wait 2-3 minutes
```

---

### ⏱️ Step 3: GET CREDENTIALS (2 minutes)

**If using Cloud Supabase:**
1. Open your project dashboard
2. Click **Settings** (⚙️ icon)
3. Click **API** in left sidebar
4. Copy:
   - **Project URL** (example: `https://abcdefg.supabase.co`)
   - **Anon Public Key** (starts with `eyJhbGc...`)
5. **PASTE THESE IN YOUR NOTES - YOU'LL NEED THEM NEXT**

---

### ⏱️ Step 4: UPDATE CONFIG (3 minutes)

**File to edit:** `c:\Users\HP\Downloads\MyGabon\lib\providers\supabase_provider.dart`

Find this section (around line 10):
```dart
Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://YOUR_SUPABASE_URL.supabase.co',  // ← REPLACE THIS
    anonKey: 'YOUR_SUPABASE_ANON_KEY',             // ← REPLACE THIS
  );
}
```

Replace with YOUR actual credentials:
```dart
Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://abcdefghijklmnop.supabase.co',   // Your Project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',  // Your Anon Key
  );
}
```

**SAVE THE FILE** (Ctrl+S)

---

### ⏱️ Step 5: CREATE DATABASE TABLES (5 minutes)

1. Open Supabase dashboard
2. Click **SQL Editor** (left sidebar)
3. Click **New Query**
4. Paste entire SQL from below (it's at the end)
5. Click **Run**
6. Wait for success message

---

### ⏱️ Step 6: INSTALL FLUTTER (8 minutes)

```bash
# Open PowerShell
cd c:\Users\HP\Downloads\MyGabon

# Clean previous builds
flutter clean

# Install all packages
flutter pub get

# Wait 3-4 minutes...

# Generate models
flutter pub run build_runner build

# Wait 2-3 minutes...
```

**Expected output:** "✅ Built successfully"

---

### ⏱️ Step 7: LAUNCH APP (4 minutes)

```bash
# Still in PowerShell, run:
flutter run -d chrome --target lib/main_modern.dart

# Wait for Chrome to open...
# Expected: App loads with GabonConnect logo
```

---

### ⏱️ Step 8: TEST (5 minutes)

**In the app:**

1. ✅ **Home Tab** - See featured products
2. ✅ **Services Tab** - See 9 services
3. ✅ **Post Tab** - Form loads
4. ✅ **Marketplace Tab** - Products list
5. ✅ **Profile Tab** - User info

**Click a product → Detail page opens**

**Click "Payer via MyGabon" → Checkout screen appears**

---

## 🎉 DONE! Your app is running!

---

## 📋 DATABASE SQL (Copy & Paste into Supabase)

```sql
-- Create users table
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

-- Create services table
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

-- Create products table
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

-- Create transactions table
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

-- Create user wallets table
CREATE TABLE IF NOT EXISTS user_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id),
  balance DECIMAL(10, 2) DEFAULT 0,
  updated_at TIMESTAMP DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_wallets ENABLE ROW LEVEL SECURITY;

-- Create public read policies
CREATE POLICY "Public read" ON users FOR SELECT USING (true);
CREATE POLICY "Public read" ON services FOR SELECT USING (true);
CREATE POLICY "Public read" ON products FOR SELECT USING (true);
CREATE POLICY "Public read" ON transactions FOR SELECT USING (true);

-- Insert demo users
INSERT INTO users (id, email, full_name, phone_number, bio, verified, rating) VALUES
  (gen_random_uuid(), 'jean.mbadinga@gmail.com', 'Jean Mbadinga', '+241612345678', 'Électricien professionnel', true, 4.8),
  (gen_random_uuid(), 'marie.ondoua@gmail.com', 'Marie Ondoua', '+241614567890', 'Experte en nettoyage', true, 4.9),
  (gen_random_uuid(), 'claude.nkomo@gmail.com', 'Claude Nkomo', '+241616789012', 'Réparateur informatique', true, 4.7),
  (gen_random_uuid(), 'sophie.ivie@gmail.com', 'Sophie Ivié', '+241618901234', 'Vendeuse de mode', true, 4.8),
  (gen_random_uuid(), 'pierre.mboumbou@gmail.com', 'Pierre Mboumbou', '+241610234567', 'Menuisier', true, 4.6),
  (gen_random_uuid(), 'fatima.traore@gmail.com', 'Fatima Traoré', '+241612345670', 'Coiffure luxe', true, 4.9),
  (gen_random_uuid(), 'jean.client@gmail.com', 'Jean Client', '+241620000000', 'Acheteur', false, 0),
  (gen_random_uuid(), 'alice.dupont@gmail.com', 'Alice Dupont', '+241621111111', 'Acheteuse', false, 0);

-- Insert demo services (using subqueries to get user IDs)
WITH user_ids AS (
  SELECT id, email FROM users
)
INSERT INTO services (provider_id, title, description, price, category, rating) VALUES
  ((SELECT id FROM users WHERE email='jean.mbadinga@gmail.com'), 'Installation électrique', 'Installation électrique professionnelle', 50000, 'Électricité', 4.8),
  ((SELECT id FROM users WHERE email='jean.mbadinga@gmail.com'), 'Réparation électrique', 'Réparation rapide et efficace', 25000, 'Électricité', 4.9),
  ((SELECT id FROM users WHERE email='marie.ondoua@gmail.com'), 'Nettoyage maison', 'Nettoyage résidentiel complet', 30000, 'Nettoyage', 4.9),
  ((SELECT id FROM users WHERE email='marie.ondoua@gmail.com'), 'Nettoyage bureau', 'Nettoyage professionnel', 45000, 'Nettoyage', 4.7),
  ((SELECT id FROM users WHERE email='claude.nkomo@gmail.com'), 'Réparation ordinateur', 'Diagnostic et réparation', 25000, 'Informatique', 4.7),
  ((SELECT id FROM users WHERE email='claude.nkomo@gmail.com'), 'Installation réseau', 'Installation réseau pro', 75000, 'Informatique', 4.8),
  ((SELECT id FROM users WHERE email='pierre.mboumbou@gmail.com'), 'Menuiserie custom', 'Menuiserie sur mesure', 60000, 'Menuiserie', 4.6),
  ((SELECT id FROM users WHERE email='fatima.traore@gmail.com'), 'Coiffure femme', 'Coiffure et stylisme', 15000, 'Beauté', 4.9),
  ((SELECT id FROM users WHERE email='fatima.traore@gmail.com'), 'Coiffure homme', 'Coupe et entretien', 8000, 'Beauté', 4.8);

-- Insert demo products
INSERT INTO products (seller_id, title, description, price, category, condition, location) VALUES
  ((SELECT id FROM users WHERE email='sophie.ivie@gmail.com'), 'iPhone 14 Pro', 'Téléphone excellente condition', 850000, 'Électronique', 'Neuf', 'Libreville'),
  ((SELECT id FROM users WHERE email='claude.nkomo@gmail.com'), 'Laptop Gaming', 'RTX 4080, haute performance', 1200000, 'Électronique', 'Bon état', 'Port-Gentil'),
  ((SELECT id FROM users WHERE email='sophie.ivie@gmail.com'), 'Vêtements été', 'Collection été exclusive', 45000, 'Vêtements', 'Neuf', 'Libreville'),
  ((SELECT id FROM users WHERE email='sophie.ivie@gmail.com'), 'Chaussures Nike', 'Baskets authentiques', 75000, 'Vêtements', 'Neuf', 'Libreville'),
  ((SELECT id FROM users WHERE email='sophie.ivie@gmail.com'), 'Sacs cuir', 'Sacs cuir véritable', 120000, 'Accessoires', 'Bon état', 'Libreville');
```

---

## ✅ What You Now Have

✅ **5 Complete Screens**
- Home (featured products)
- Services (9 Gabon services)
- Post (create listings)
- Marketplace (products)
- Profile (user account)

✅ **Payment System**
- Checkout with 5% fee calculation
- Airtel Money OTP confirmation
- Success screen with animation

✅ **Real Gabon Data**
- 8 users with ratings
- 9 services in FCFA
- 5 products ready to buy
- Transaction history

✅ **Modern Design**
- Gabon colors (Green, Yellow, Navy)
- Floating pill navigation bar
- Beautiful cards with shadows
- Smooth animations

---

## 🚀 What's Next?

**After you see the app running (30 minutes):**

1. **Test All Features** (30 minutes)
   - Click through all tabs
   - Test payment flow
   - Create listings

2. **Add Authentication** (3 hours)
   - Create login screen
   - Add signup
   - Update main app

3. **Real Airtel Money** (3 hours)
   - Get API credentials
   - Integrate payment

4. **Deploy** (1 hour)
   - Build web version
   - Deploy to Firebase Hosting
   - Share live link

---

## ⚠️ Troubleshooting

### "Flutter not found"
```bash
# Add Flutter to PATH (Windows)
# Or use full path: C:\flutter\bin\flutter run -d chrome
```

### "Supabase connection error"
- Check URL and Key are correct
- Verify Supabase project is "active"
- Check internet connection

### "Database table error"
- Make sure you pasted all SQL
- Run SQL line by line if needed
- Check for typos

### "Models not generated"
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📞 Need Help?

1. Check **QUICK_START.md** for troubleshooting
2. Check Supabase docs: https://supabase.com/docs
3. Check Flutter docs: https://flutter.dev/docs

---

## 🎯 Your Goal Today

**Make this one command work:**
```bash
flutter run -d chrome --target lib/main_modern.dart
```

**When you see the app load with GabonConnect logo → YOU WIN!** 🎉

---

**GO! Start with Step 1 right now! ⚡**

🇬🇦 GabonConnect - Connecting Gabon!
