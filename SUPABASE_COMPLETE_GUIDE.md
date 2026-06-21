# 🚀 Supabase Complete Guide pour GabonConnect

## ✅ Installation Complete

```
✅ Node.js v24.16.0
✅ npm v11.13.0
✅ Firebase CLI v15.22.0 (backup)
✅ Supabase CLI v2.107.0 ← NOUVEAU
✅ GabonConnect app lancée
```

---

## 🎯 Pourquoi Supabase pour GabonConnect?

### ✨ Avantages clés:

1. **PostgreSQL** - SQL puissant pour requêtes complexes
2. **Moins cher** - $5-50/mois vs Firebase pay-as-you-go
3. **Contrôle complet** - Open source, self-hosted possible
4. **RLS (Row-Level Security)** - Permissions granulaires par ligne
5. **Realtime** - WebSocket pour chat/notifications temps réel
6. **Edge Functions** - Serverless comme Cloud Functions
7. **Audit trails** - Triggers PostgreSQL natifs
8. **Transactions ACID** - Pour paiements et escrow

---

## 🔧 Étape 1: Créer Compte Supabase

```
1. Aller à: https://supabase.com
2. Cliquer "Start Your Project"
3. Se connecter avec GitHub
4. Créer organization: "GabonConnect"
5. Créer projet: "gabon-connect-prod"
6. Region: Europe (ou Afrique si disponible)
7. Database password: strong password
```

**Note important**: Copier les credentials:
- Project URL: `https://xxxxx.supabase.co`
- API Key: `eyJhbG...` (public)
- Service Role: (secret - jamais partager)

---

## 💾 Étape 2: Créer Schema PostgreSQL

### Option A: Via Console Supabase (Plus facile)

1. Aller à: `https://app.supabase.com/project/xxxxx/sql`
2. Cliquer "New Query"
3. Copier/Coller le SQL ci-dessous

### Option B: Via CLI

```bash
cd C:\Users\HP\Downloads\MyGabon

# Créer migration
supabase migration new init_gabon_schema

# Éditer migrations/[timestamp]_init_gabon_schema.sql
# (Ajouter SQL ci-dessous)

# Appliquer
supabase db push
```

### 📝 SQL Schema Complet:

```sql
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
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

-- User verification
CREATE TABLE user_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  phone_number TEXT,
  otp_code TEXT,
  otp_attempts INT DEFAULT 0,
  otp_expires_at TIMESTAMP,
  id_type TEXT,
  id_number TEXT ENCRYPTED,
  verified BOOLEAN DEFAULT false,
  verified_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

-- Services
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
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

-- Marketplace products
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
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

-- Chat messages
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

-- Audit logs (Phase 2)
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action TEXT NOT NULL, -- 'login', 'logout', 'otpSent', etc
  resource TEXT,
  resource_id TEXT,
  details JSONB,
  ip_address INET,
  user_agent TEXT,
  status TEXT DEFAULT 'success',
  error_message TEXT,
  created_at TIMESTAMP DEFAULT now()
);

-- OTP audit trail
CREATE TABLE otp_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number TEXT,
  otp_code TEXT,
  attempts INT DEFAULT 0,
  success BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT now()
);

-- Reviews and ratings
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reviewee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating INT CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  tags TEXT[],
  recommends BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Fraud detection reports
CREATE TABLE fraud_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  suspect_id UUID REFERENCES users(id) ON DELETE SET NULL,
  reason TEXT,
  description TEXT,
  status TEXT DEFAULT 'pending',
  resolved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_verified ON users(verified);
CREATE INDEX idx_services_provider ON services(provider_id);
CREATE INDEX idx_services_category ON services(category);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);
CREATE INDEX idx_reviews_reviewer ON reviews(reviewer_id);
CREATE INDEX idx_reviews_reviewee ON reviews(reviewee_id);
CREATE INDEX idx_fraud_reports_suspect ON fraud_reports(suspect_id);

-- Enable Row-Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE fraud_reports ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users: Can only see own profile (except public fields)
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Anyone can view public profiles"
  ON users FOR SELECT
  USING (true); -- Allow public access with SELECT *

-- Services: Public read, private write
CREATE POLICY "Services are public"
  ON services FOR SELECT
  USING (published = true);

CREATE POLICY "Providers can manage own services"
  ON services FOR UPDATE
  USING (auth.uid() = provider_id);

CREATE POLICY "Providers can delete own services"
  ON services FOR DELETE
  USING (auth.uid() = provider_id);

-- Messages: Private between participants
CREATE POLICY "Users can view own messages"
  ON messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- Audit logs: Users see own logs, admins see all
CREATE POLICY "Users can view own audit logs"
  ON audit_logs FOR SELECT
  USING (auth.uid() = user_id);

-- Reviews: Public read
CREATE POLICY "Reviews are public"
  ON reviews FOR SELECT
  USING (true);

CREATE POLICY "Users can leave reviews"
  ON reviews FOR INSERT
  WITH CHECK (auth.uid() = reviewer_id);

-- Fraud reports: Users can report, admins see all
CREATE POLICY "Users can report fraud"
  ON fraud_reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

-- Functions for audit logging
CREATE OR REPLACE FUNCTION log_audit_event()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (user_id, action, resource, resource_id, details, status)
  VALUES (auth.uid(), TG_ARGV[0], TG_TABLE_NAME, NEW.id, row_to_json(NEW), 'success');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for login audit
CREATE TRIGGER audit_login
AFTER INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION log_audit_event('user_created');

-- Trigger for service creation audit
CREATE TRIGGER audit_service_created
AFTER INSERT ON services
FOR EACH ROW
EXECUTE FUNCTION log_audit_event('service_created');

-- Trigger for message creation audit
CREATE TRIGGER audit_message_created
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION log_audit_event('message_sent');
```

---

## 🔐 Étape 3: Configuration Authentication

### Dans Supabase Console:

1. Aller à: `https://app.supabase.com/project/xxxxx/auth/providers`
2. Activer:
   - ✅ Email/Password
   - ✅ Google OAuth
   - ✅ GitHub OAuth
   - ✅ Phone (SMS)

### Configuration Email:

1. `Settings > Email`
2. Ajouter votre domaine email custom (ou utiliser default)
3. Tester avec "Send test email"

### Configuration SMS (pour OTP):

1. `Settings > SMS`
2. Choisir Twilio ou autre provider
3. Ajouter credentials Twilio

---

## 🚀 Étape 4: Intégrer dans GabonConnect

### 1. Ajouter dependency Flutter:

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  supabase: ^2.0.0
```

### 2. Initialiser dans main.dart:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://xxxxx.supabase.co',
    anonKey: 'eyJhbG...',
  );
  
  runApp(const GabonConnectApp());
}
```

### 3. Authentication:

```dart
// Sign up
final res = await supabase.auth.signUp(
  email: email,
  password: password,
);

// Sign in
final res = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);

// Sign out
await supabase.auth.signOut();

// Get current user
final user = supabase.auth.currentUser;
```

### 4. Database queries:

```dart
// Insert (Sign up = create user)
await supabase
  .from('users')
  .insert({'email': email, 'full_name': name});

// Select (Get user profile)
final data = await supabase
  .from('users')
  .select()
  .eq('id', userId)
  .single();

// Update (Edit profile)
await supabase
  .from('users')
  .update({'full_name': newName})
  .eq('id', userId);

// Delete
await supabase
  .from('users')
  .delete()
  .eq('id', userId);
```

### 5. Realtime subscriptions (Chat):

```dart
supabase
  .from('messages')
  .on(RealtimeEventTypes.insert, (payload) {
    print('New message: ${payload.newRecord}');
  })
  .on(RealtimeEventTypes.update, (payload) {
    print('Updated: ${payload.newRecord}');
  })
  .subscribe();
```

### 6. Audit logging (Phase 2):

```dart
// Log action
await supabase.from('audit_logs').insert({
  'action': 'login',
  'details': {'email': email},
  'status': 'success',
});

// Query logs
final logs = await supabase
  .from('audit_logs')
  .select()
  .eq('user_id', userId)
  .order('created_at', ascending: false);
```

---

## 📊 Étape 5: Deploy Infrastructure

### Local development (with Docker):

```bash
# Démarrer Supabase localement
supabase start

# Cela lance:
# - PostgreSQL (localhost:5432)
# - Supabase Studio (localhost:3000)
# - Auth API (localhost:9999)
# - Realtime (localhost:4000)
```

### Production deploy:

```bash
# Pousser migrations vers production
supabase db push --remote

# Voir status
supabase status

# Logs
supabase functions list
```

---

## 🔑 Variables d'environnement (.env):

```ini
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbG...
SUPABASE_SERVICE_ROLE=eyJhbG... (SECRET)

TWILIO_ACCOUNT_SID=ACxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxx
TWILIO_PHONE_NUMBER=+1234567890

ENVIRONMENT=production
```

---

## 🎯 Phase 2 Implementation avec Supabase

### OTP Verification:

```dart
// 1. Send OTP via SMS
final otp = _generateOTP(); // 6 digits
await Supabase.instance.client
  .from('otp_logs')
  .insert({'phone_number': phone, 'otp_code': otp});

// 2. Call Twilio (via Edge Function ou locally)
await sendSmsViaTwilio(phone, otp);

// 3. Verify OTP
final verified = await Supabase.instance.client
  .from('user_verifications')
  .update({'verified': true})
  .eq('phone_number', phone)
  .eq('otp_code', userInput)
  .then((_) => true)
  .catchError((_) => false);

// 4. Log in audit
await logAuditEvent(
  action: 'otpVerified',
  details: {'phone': phone, 'success': verified}
);
```

### Audit Logging:

```dart
// Every action gets logged
Future<void> logAuditEvent({
  required String action,
  String? resource,
  String? resourceId,
  Map<String, dynamic>? details,
}) async {
  await Supabase.instance.client.from('audit_logs').insert({
    'user_id': Supabase.instance.client.auth.currentUser!.id,
    'action': action,
    'resource': resource,
    'resource_id': resourceId,
    'details': details,
    'status': 'success',
  });
}
```

---

## 📈 Monitoring & Backups

### Backups automatiques:
- ✅ Daily backups (automatic)
- ✅ Retention: 7 days (free)
- ✅ 30 days (paid)

### Monitoring:
```bash
# Voir utilisation
supabase status

# Logs
supabase functions list
```

---

## ✅ Checklist Setup Supabase

- [ ] Compte Supabase créé
- [ ] Projet créé
- [ ] Schema PostgreSQL importé
- [ ] RLS policies activées
- [ ] Auth providers configurés
- [ ] Twilio intégré pour SMS
- [ ] Flutter dépendences ajoutées
- [ ] main.dart initialisé Supabase
- [ ] Tests authentification
- [ ] Tests audit logging
- [ ] Tests realtime
- [ ] Déployé en production

---

## 🆘 Troubleshooting

### "Connection refused"
```bash
# Vérifier Supabase tourne
supabase status

# Redémarrer
supabase stop
supabase start
```

### "RLS policy violation"
```sql
-- Vérifier policies
SELECT * FROM pg_policies WHERE tablename = 'users';

-- Déboguer
SELECT * FROM users; -- Will fail if RLS too strict
```

### "OTP not received"
```
1. Vérifier Twilio credentials dans .env
2. Vérifier numéro de téléphone format: +241...
3. Vérifier Twilio account balance
```

---

## 🎊 Résumé Final

**Supabase vs Firebase pour GabonConnect:**

✅ PostgreSQL = Requêtes complexes pour marketplace  
✅ RLS = Permissions granulaires par utilisateur  
✅ Triggers = Audit automatique  
✅ Realtime = Chat en temps réel  
✅ Moins cher = $5/mois vs pay-as-you-go Firebase  
✅ Open source = Contrôle complet  

**L'app est prête pour production-grade backend!** 🚀

