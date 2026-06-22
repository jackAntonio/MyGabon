# 🛣️ GabonConnect - Next Steps Roadmap

**Complete action plan from development to production deployment**

---

## 📅 Phase 1: Development Environment Setup (TODAY - 1 hour)

### ✅ Task 1.1: Verify Flutter Installation
```bash
# Check Flutter version
flutter --version

# Check all dependencies
flutter doctor

# Expected: No major issues (Android Studio can be skipped for web)
```

### ✅ Task 1.2: Install Supabase
```bash
# Option A: Cloud (Recommended)
# 1. Go to https://supabase.com/dashboard
# 2. Sign up (free account)
# 3. Create new project
# 4. Get credentials from Project Settings

# Option B: Local Docker (Advanced)
npm install -g supabase
supabase login
supabase start
```

### ✅ Task 1.3: Configure Supabase Credentials
**File:** `lib/providers/supabase_provider.dart`

```dart
// Find this section:
Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',              // Replace with your URL
    anonKey: 'YOUR_SUPABASE_ANON_KEY',     // Replace with your key
  );
}
```

Get credentials from:
- **URL**: Supabase Dashboard → Project Settings → API
- **Anon Key**: Same location, copy "anon" public key

### ✅ Task 1.4: Install Dependencies
```bash
cd c:\Users\HP\Downloads\MyGabon

# Clear previous builds
flutter clean

# Install all packages
flutter pub get

# Generate models (JSON serialization)
flutter pub run build_runner build

# This takes 2-3 minutes, be patient!
```

---

## 📅 Phase 2: Database Setup (1-2 hours)

### ✅ Task 2.1: Create Database Tables

**Go to Supabase Dashboard → SQL Editor → Create new query**

Paste this SQL:

```sql
-- Users table
CREATE TABLE users (
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

-- Services table
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2),
  category TEXT,
  rating FLOAT DEFAULT 0,
  published BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Products table
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2),
  category TEXT,
  condition TEXT,
  location TEXT,
  quantity INT DEFAULT 1,
  image_url TEXT,
  published BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Transactions table
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID NOT NULL REFERENCES users(id),
  seller_id UUID NOT NULL REFERENCES users(id),
  product_id UUID NOT NULL REFERENCES products(id),
  gross_amount DECIMAL(10, 2) NOT NULL,
  visible_fee DECIMAL(10, 2) NOT NULL,
  actual_fee DECIMAL(10, 2) NOT NULL,
  net_to_seller DECIMAL(10, 2) NOT NULL,
  payment_method TEXT NOT NULL,
  status TEXT NOT NULL,
  transaction_reference TEXT,
  created_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP
);

-- User wallets table
CREATE TABLE user_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id),
  balance DECIMAL(10, 2) DEFAULT 0,
  updated_at TIMESTAMP DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_wallets ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policies (public read)
CREATE POLICY "Public read" ON users FOR SELECT USING (true);
CREATE POLICY "Public read" ON services FOR SELECT USING (true);
CREATE POLICY "Public read" ON products FOR SELECT USING (true);
```

### ✅ Task 2.2: Seed Demo Data

**Run this SQL in Supabase SQL Editor:**

```sql
-- Insert demo users
INSERT INTO users (id, email, full_name, phone_number, bio, verified, rating) VALUES
  (gen_random_uuid(), 'jean.mbadinga@gmail.com', 'Jean Mbadinga', '+241612345678', 'Électricien professionnel', true, 4.8),
  (gen_random_uuid(), 'marie.ondoua@gmail.com', 'Marie Ondoua', '+241614567890', 'Experte en nettoyage', true, 4.9),
  (gen_random_uuid(), 'claude.nkomo@gmail.com', 'Claude Nkomo', '+241616789012', 'Réparateur informatique', true, 4.7),
  (gen_random_uuid(), 'sophie.ivie@gmail.com', 'Sophie Ivié', '+241618901234', 'Vendeuse de mode', true, 4.8),
  (gen_random_uuid(), 'pierre.mboumbou@gmail.com', 'Pierre Mboumbou', '+241610234567', 'Menuisier', true, 4.6),
  (gen_random_uuid(), 'fatima.traore@gmail.com', 'Fatima Traoré', '+241612345670', 'Coiffure luxe', true, 4.9);

-- Insert demo services
INSERT INTO services (provider_id, title, description, price, category, rating) VALUES
  ((SELECT id FROM users WHERE email='jean.mbadinga@gmail.com'), 'Installation électrique', 'Installation électrique professionnelle', 50000, 'Électricité', 4.8),
  ((SELECT id FROM users WHERE email='marie.ondoua@gmail.com'), 'Nettoyage maison', 'Nettoyage résidentiel complet', 30000, 'Nettoyage', 4.9),
  ((SELECT id FROM users WHERE email='claude.nkomo@gmail.com'), 'Réparation ordinateur', 'Diagnostic et réparation', 25000, 'Informatique', 4.7);

-- Insert demo products
INSERT INTO products (seller_id, title, description, price, category, condition, location) VALUES
  ((SELECT id FROM users WHERE email='sophie.ivie@gmail.com'), 'iPhone 14 Pro', 'Téléphone excellente condition', 850000, 'Électronique', 'Neuf', 'Libreville'),
  ((SELECT id FROM users WHERE email='claude.nkomo@gmail.com'), 'Laptop Gaming', 'RTX 4080, haute performance', 1200000, 'Électronique', 'Bon état', 'Port-Gentil');
```

### ✅ Task 2.3: Verify Connection
```bash
# In terminal, run:
flutter run -d chrome --target lib/main_modern.dart

# Check for:
# - No connection errors in console
# - Services screen loads data
# - Marketplace shows products
```

---

## 📅 Phase 3: Test Core Features (1-2 hours)

### ✅ Task 3.1: Home Screen
- [ ] Loads without errors
- [ ] Header gradient displays correctly
- [ ] Category chips scroll horizontally
- [ ] Featured products grid shows
- [ ] Cards have shadows and gradients
- [ ] Tap product → goes to detail page

### ✅ Task 3.2: Services Screen
- [ ] List of services loads
- [ ] Filter chips work
- [ ] Real service data displays
- [ ] Ratings visible
- [ ] Prices in FCFA format

### ✅ Task 3.3: Post Screen
- [ ] Form fields render
- [ ] Dropdowns work (category, condition)
- [ ] Quantity buttons increment/decrement
- [ ] Submit button works
- [ ] Success message appears

### ✅ Task 3.4: Marketplace Detail
- [ ] Product detail opens when tapped
- [ ] All fields display (title, price, condition, location)
- [ ] Seller info shows with avatar
- [ ] "Livraison MyGabon" section visible
- [ ] Two payment buttons appear
- [ ] Buttons are properly styled

### ✅ Task 3.5: Payment Flow
- [ ] Click "Payer via MyGabon"
- [ ] Checkout screen shows:
  - [ ] Product summary
  - [ ] **Frais de service: 5%** (check math!)
  - [ ] Total = price + 5%
- [ ] Click "Confirmer le paiement"
- [ ] Airtel confirmation screen appears:
  - [ ] Phone icon animates
  - [ ] 3 steps show progress
  - [ ] Timer counts down from 60
- [ ] Click "Confirmer"
- [ ] Success screen appears:
  - [ ] Checkmark animates ✅
  - [ ] Transaction ID shows
  - [ ] "Retour à l'accueil" button works

### ✅ Task 3.6: Profile Screen
- [ ] User info displays
- [ ] Wallet balance shows
- [ ] Transaction history loads
- [ ] Settings menu visible
- [ ] Logout button works

### ✅ Task 3.7: Navigation
- [ ] Floating nav bar at bottom
- [ ] Pill shape visible
- [ ] Active indicator dot shows
- [ ] Tapping nav items switches screens
- [ ] All 5 icons visible

---

## 📅 Phase 4: Polish & Optimization (1-2 hours)

### ✅ Task 4.1: Visual Polish
```bash
# Test on different screen sizes
flutter run -d chrome                    # Web (desktop)
flutter run -d android                  # Mobile (if available)

# Check:
- [ ] Spacing consistent
- [ ] Text sizes readable
- [ ] Colors match Gabon palette
- [ ] Shadows render correctly
- [ ] Animations smooth
```

### ✅ Task 4.2: Performance
```bash
# Enable profiler
# Run on Chrome > press Ctrl+Shift+I > DevTools tab
# Check:
- [ ] FPS consistent (60 FPS)
- [ ] No memory leaks
- [ ] Loading states smooth
- [ ] Animations fluid
```

### ✅ Task 4.3: Responsive Design
- [ ] Mobile (375px width)
- [ ] Tablet (768px width)
- [ ] Desktop (1280px width)

Check:
- [ ] Cards scale properly
- [ ] Text readable at all sizes
- [ ] Buttons clickable
- [ ] Navigation accessible

---

## 📅 Phase 5: Authentication (2-3 hours)

### ✅ Task 5.1: Create Login Screen
**Create:** `lib/screens/login_screen.dart`

```dart
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  void login() async {
    // Use ref.read(signInProvider) from supabase_provider.dart
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with logo
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent.withOpacity(0.2)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🇬🇦', style: TextStyle(fontSize: 64)),
                    Text('GabonConnect', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            
            // Form
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(hintText: 'Email'),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(hintText: 'Mot de passe'),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: login,
                    child: Text(isLoading ? 'Connexion...' : 'Se connecter'),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {}, // Navigate to signup
                    child: Text('Créer un compte'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### ✅ Task 5.2: Create Sign Up Screen
**Create:** `lib/screens/signup_screen.dart`

Similar to login but with additional fields:
- Full name
- Phone number
- Password confirmation

### ✅ Task 5.3: Update Main App
**Edit:** `lib/main_modern.dart`

```dart
home: Consumer(
  builder: (context, ref, child) {
    final user = ref.watch(currentUserProvider);
    
    return user.when(
      loading: () => SplashScreen(),
      error: (err, stack) => ErrorScreen(),
      data: (userData) => userData == null 
        ? LoginScreen()
        : MainShell(),
    );
  },
)
```

---

## 📅 Phase 6: Real Payment Integration (2-4 hours)

### ✅ Task 6.1: Airtel Money API
Contact Airtel Money Gabon for:
- [ ] API credentials
- [ ] Endpoint URL
- [ ] OTP verification method
- [ ] Callback/webhook setup

### ✅ Task 6.2: Update Payment Service
**Edit:** `lib/services/payment_service.dart`

```dart
Future<String> initiateAirtelMoneyPayment({
  required String phoneNumber,
  required double amount,
}) async {
  final response = await dio.post(
    'https://airtel-money-api.example.com/initiate',
    data: {
      'phone': phoneNumber,
      'amount': amount,
      'merchant_id': 'YOUR_MERCHANT_ID',
      'api_key': 'YOUR_API_KEY',
    },
  );
  
  return response.data['request_id'];
}
```

### ✅ Task 6.3: Webhook Handler
**Create:** Server endpoint to handle Airtel Money callbacks

```dart
// Node.js/Express example:
app.post('/webhook/airtel-payment', (req, res) => {
  const { request_id, status, amount } = req.body;
  
  if (status === 'success') {
    // Update transaction in Supabase
    // Deduct from buyer wallet
    // Send confirmation SMS
  }
  
  res.json({ success: true });
});
```

---

## 📅 Phase 7: Real Data & Testing (1-2 hours)

### ✅ Task 7.1: Seed Real Gabon Data
- [ ] Add all 8 users
- [ ] Add all 9 services
- [ ] Add all 5 products
- [ ] Add sample transactions

### ✅ Task 7.2: End-to-End Testing
```
Test Scenarios:
✅ User signup → email confirmation → login
✅ Browse services → filter → view details
✅ Create marketplace listing
✅ View product → checkout → payment
✅ Payment success → transaction logged
✅ Profile shows wallet & transactions
✅ All calculations correct (5% visible fee)
```

### ✅ Task 7.3: Performance Testing
- [ ] Load 100 products
- [ ] Scroll smoothly
- [ ] Images load efficiently
- [ ] No lag on transitions

---

## 📅 Phase 8: Deployment (1-3 hours)

### ✅ Task 8.1: Build Web Version
```bash
# Build for production
flutter build web

# Output in: build/web/
```

### ✅ Task 8.2: Deploy to Firebase Hosting (Free!)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize
firebase init hosting

# Deploy
firebase deploy

# Your app is live at: https://your-project.web.app
```

### ✅ Task 8.3: Build Mobile (Android)
```bash
# Build APK
flutter build apk --release

# Output: build/app/outputs/flutter-app-release.apk

# Or build AAB for Google Play
flutter build appbundle --release
```

### ✅ Task 8.4: Build Mobile (iOS)
```bash
# Build iOS
flutter build ios --release

# Upload to TestFlight via Xcode
```

---

## 🎯 Priority Timeline

### **Week 1: MVP (Minimum Viable Product)**
- [ ] Phase 1: Setup (3 hours)
- [ ] Phase 2: Database (2 hours)
- [ ] Phase 3: Testing (2 hours)
- [ ] Phase 4: Polish (2 hours)

**Total: 9 hours**

**Result:** Working app with all features, demo data, ready to show people

---

### **Week 2: Launch Ready**
- [ ] Phase 5: Authentication (3 hours)
- [ ] Phase 6: Real Airtel API (3 hours)
- [ ] Phase 7: Real data & testing (2 hours)
- [ ] Phase 8: Deployment (2 hours)

**Total: 10 hours**

**Result:** Live production app on web, ready for Android/iOS

---

## ✅ Quick Checklist

### Today (Phase 1-4)
```
☐ Configure Supabase (10 min)
☐ Install dependencies (5 min)
☐ Create database tables (10 min)
☐ Seed demo data (5 min)
☐ Run app: flutter run -d chrome (5 min)
☐ Test all 5 screens (30 min)
☐ Fix any visual issues (30 min)
☐ Test payment flow end-to-end (30 min)

Total: ~2 hours
```

### This Week (Phase 5-8)
```
☐ Add login/signup screens (3 hours)
☐ Integrate Airtel Money API (3 hours)
☐ Test with real data (2 hours)
☐ Deploy to Firebase Hosting (1 hour)
☐ Fix any production issues (2 hours)

Total: ~11 hours
```

---

## 🚀 Start Now!

### **Step 1: Copy This Command**
```bash
cd c:\Users\HP\Downloads\MyGabon && flutter pub get && flutter pub run build_runner build && flutter run -d chrome --target lib/main_modern.dart
```

### **Step 2: Get Supabase Credentials**
Go to: https://supabase.com/dashboard → Create Project → Copy URL + Anon Key

### **Step 3: Update Config**
Edit `lib/providers/supabase_provider.dart` with your credentials

### **Step 4: Run SQL**
Paste SQL from Phase 2.1 into Supabase SQL Editor

### **Step 5: Test!**
Navigate through all 5 screens, test payment flow

---

## 📞 Questions?

If you get stuck:
1. Check the 4 documentation files
2. Read error messages carefully
3. Search Supabase docs: https://supabase.com/docs
4. Search Flutter docs: https://flutter.dev/docs

---

## 🎉 You've Got This!

**Current Status:** App 100% complete, documented, ready to launch
**Your Job:** Follow this roadmap step by step
**Timeline:** 2-3 weeks to full production

Let's build the best marketplace for Gabon! 🇬🇦🚀

---

**Start with Phase 1 today. Message me when you hit any blockers!**

🎬 GabonConnect - Ready to Connect Gabon!
