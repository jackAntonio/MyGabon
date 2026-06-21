# 🚀 PHASE 2: QUICKSTART COMMANDES

**Durée**: ~2-3 semaines pour complétude  
**Complexité**: Intermédiaire  
**Dépendances**: Firebase, Twilio, Network

---

## 📋 SETUP INITIAL (30 min)

### 1. Ajouter Dépendances

```bash
cd c:\Users\HP\Downloads\MyGabon

# Ajouter à pubspec.yaml:
# - flutter_dotenv: ^5.1.0
# - http: ^1.1.0

flutter pub add flutter_dotenv http

# Vérifier dépendances
flutter pub get
```

### 2. Créer fichier .env

```bash
# Windows PowerShell
Copy-Item .env.example .env

# Ou manuel:
# Créer fichier: c:\Users\HP\Downloads\MyGabon\.env
```

### 3. Configurer .env

```ini
# Dans .env - REMPLACER les valeurs

# Twilio SMS
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_PHONE_NUMBER=+1234567890

# Environment
ENVIRONMENT=development
ENABLE_SMS_VERIFICATION=true
ENABLE_PUSH_NOTIFICATIONS=true
```

### 4. Initialiser Flutter Dotenv

```dart
// lib/main.dart - ligne 1
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); // ← Ajouter cette ligne
  // ... rest of init
}
```

---

## 🔧 SETUP SERVICES (1-2 heures)

### Étape 1: Twilio Account (15 min)

```bash
# 1. Aller à https://www.twilio.com/console
# 2. Créer compte (gratuit 15€ crédit)
# 3. Récupérer:
#    - Account SID
#    - Auth Token
#    - Numéro Twilio (ex: +1234567890)
# 4. Copier dans .env
```

### Étape 2: Firebase FCM (15 min)

```bash
# 1. Aller à Firebase Console
# 2. Sélectionner projet
# 3. Aller à Cloud Messaging
# 4. Récupérer Server Key
# 5. Configurer:
#    - Android: google-services.json ✓ (déjà fait)
#    - iOS: GoogleService-Info.plist ✓ (déjà fait)
```

### Étape 3: Firestore Collections (15 min)

```bash
# 1. Firebase Console > Firestore Database
# 2. Créer collections:
#    ☐ auditLogs
#    ☐ notifications
# 3. Importer règles de sécurité:
#    firebase deploy --only firestore:rules
```

---

## 📝 CODE IMPLEMENTATION (3-5 jours)

### Jour 1: Services Core

```bash
# ✅ Déjà créés:
# - lib/services/sms_service.dart
# - lib/services/audit_log_service.dart
# - lib/services/http_client_service.dart
# - lib/services/notification_service.dart (mise à jour)
# - lib/app_services.dart

# TODO: Valider fichiers existent
ls lib/services/
```

### Jour 2-3: Intégration dans Providers

**Ajouter à `lib/providers/auth_provider.dart`:**
```dart
// 1. Importer
import '../app_services.dart';

// 2. Dans login():
await auditLog.logLogin(email: email, success: true);

// 3. Dans logout():
await auditLog.logLogout();
```

**Ajouter à `lib/providers/verification_provider.dart`:**
```dart
// 1. Importer
import '../app_services.dart';

// 2. Dans sendPhoneOTP():
final sent = await sms.sendOTP(phoneNumber: phone, otp: otp);

// 3. Logger
await auditLog.logPhoneVerification(phoneNumber: phone, verified: true);
```

### Jour 4-5: Tests & Validation

```bash
# Compiler
flutter analyze
flutter pub get

# Tester
flutter test test/integration_tests.dart
flutter test test/security_utils_test.dart

# Couverture
flutter test --coverage
```

---

## ✅ VALIDATION CHECKLIST

### SMS Functionality
- [ ] Service créé: `sms_service.dart`
- [ ] Intégré dans: `verification_provider.dart`
- [ ] Twilio credentials dans `.env`
- [ ] SMS reçu lors test

### Audit Logging
- [ ] Service créé: `audit_log_service.dart`
- [ ] Intégré dans: `auth_provider.dart`, `verification_provider.dart`
- [ ] Collection Firestore créée: `auditLogs`
- [ ] Logs visibles dans Firestore

### FCM Notifications
- [ ] Service mis à jour: `notification_service.dart`
- [ ] Permissions demandées
- [ ] FCM token obtenu
- [ ] Notifications reçues

### HTTP Client
- [ ] Service créé: `http_client_service.dart`
- [ ] Certificate pinning configuré
- [ ] Utilisé dans API calls

### Global Services
- [ ] `app_services.dart` créé
- [ ] Initialisé dans `main.dart`
- [ ] Accessible via getters

### Tests
- [ ] Tests créés: `integration_tests.dart`
- [ ] Tous les tests passent
- [ ] Coverage >80%

---

## 🧪 COMMANDES DE TEST

```bash
# Run single test file
flutter test test/integration_tests.dart

# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Watch mode
flutter test --watch

# Verbose output
flutter test --verbose

# Specific test
flutter test test/integration_tests.dart -k "SMS Service"
```

---

## 🔍 DEBUGGING

### SMS Not Received
```bash
# 1. Vérifier .env
cat .env | grep TWILIO

# 2. Vérifier logs
# Dans AndroidStudio: Logcat filter "SmsService"

# 3. Vérifier Twilio Console
# https://www.twilio.com/console/sms/logs

# 4. Tester directement
flutter run
# - Naviguer à Verification screen
# - Entrer téléphone
# - Vérifier SMS
```

### Firestore Logs Not Appearing
```bash
# 1. Vérifier collection existe
# Firebase Console > Firestore > Collection "auditLogs"

# 2. Vérifier règles
# firestore.rules doit permettre écriture

# 3. Redéployer règles
firebase deploy --only firestore:rules

# 4. Vérifier auth
# User doit être authentifié (uid != null)
```

### FCM Token Not Received
```bash
# 1. Vérifier permissions
# Android: AndroidManifest.xml permissions
# iOS: Info.plist permissions

# 2. Vérifier Firebase setup
# flutter doctor -v
# Doit afficher Firebase OK

# 3. Vérifier GoogleServices config
# google-services.json doit être valide
```

---

## 📦 DÉPENDANCES FINAL (pubspec.yaml)

```yaml
dependencies:
  # Existant
  flutter:
    sdk: flutter
  provider: ^6.0.5
  connectivity_plus: ^5.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Phase 1 (Sécurité)
  bcrypt: ^0.0.3
  dart_jsonwebtoken: ^2.12.0
  flutter_secure_storage: ^9.0.0
  
  # Phase 2 (Services)
  flutter_dotenv: ^5.1.0       # ← NOUVEAU
  http: ^1.1.0                  # ← NOUVEAU
  firebase_messaging: ^14.0.0   # (existant)
  
  # Firebase
  firebase_core: ^2.0.0
  cloud_firestore: ^4.0.0
  firebase_auth: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

---

## 🎯 PROGRESSION TRACKING

```
Phase 1 Critique:     ████████████████████ 100% ✅
Phase 2 Haute:        ████████░░░░░░░░░░░░  40% 🔄

Aujourd'hui (11 Juin):
[✅] SMS Service créé
[✅] FCM Service mis à jour
[✅] Audit Log Service créé
[✅] HTTP Client créé
[✅] App Services setup
[✅] Tests créés
[✅] Integration guide

Semaine 1:
[ ] Configurer Twilio
[ ] Configurer FCM
[ ] Intégrer dans Providers
[ ] Tester SMS/Notifications

Semaine 2:
[ ] Tester Audit Logs
[ ] Performance testing
[ ] Security audit
[ ] Documentation

Semaine 3:
[ ] Phase 3 prep (Paiements)
[ ] Production readiness
```

---

## 📊 RESSOURCES

### Documentation
- [Twilio SMS Guide](https://www.twilio.com/docs/sms)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Certificate Pinning Best Practices](https://owasp.org/www-community/attacks/Certificate_and_Public_Key_Pinning)

### Code Examples
- `INTEGRATION_GUIDE_PHASE2.md` - Détail intégration
- `test/integration_tests.dart` - Exemples tests
- `lib/app_services.dart` - Services centralisés

---

## 🆘 TROUBLESHOOTING

| Problème | Solution |
|----------|----------|
| SMS non reçu | Vérifier Twilio SID/Token, log Twilio |
| Audit logs vides | Vérifier Firestore rules, user auth |
| Notifications silence | Vérifier FCM token, device permissions |
| HTTP timeout | Vérifier URL, certificate pinning |
| Service init failure | Vérifier .env, Firebase config |

---

## ✨ NEXT STEPS

Une fois Phase 2 complétée:

1. **Phase 3**: Paiements (Stripe/M-Pesa)
2. **Performance**: Load testing, optimization
3. **Compliance**: GDPR, data protection
4. **Production**: Deployment, monitoring

---

## 📞 SUPPORT

Questions ou problèmes:
1. Consulter `INTEGRATION_GUIDE_PHASE2.md`
2. Vérifier logs: `flutter logs`
3. Consulter Firebase Console
4. Vérifier Twilio Dashboard

---

**Status**: Phase 2 Démarrage  
**Estimée Completion**: 2-3 semaines  
**Effort**: 40-60 heures dev + testing
