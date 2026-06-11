# 🔧 PLAN D'ACTION & CORRECTIONS

## Phase 1: Corrections CRITIQUES (1-2 Semaines)

### 1. Remplacer SHA256 par BCrypt pour les Mots de Passe

**Fichier à modifier**: `lib/utils/security_utils.dart`

```dart
// ❌ AVANT
static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
}

// ✅ APRÈS
import 'package:bcrypt/bcrypt.dart';

static String hashPassword(String password) {
  // Utiliser cost factor 12 (par défaut BCrypt)
  return BCrypt.hashpw(password, BCrypt.gensalt());
}

static bool verifyPassword(String password, String hash) {
  return BCrypt.checkpw(password, hash);
}
```

**pubspec.yaml à ajouter**:
```yaml
dependencies:
  bcrypt: ^0.0.3
```

---

### 2. Chiffrer Données Sensibles Locales

**Ajouter à pubspec.yaml**:
```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  encrypted_hive: ^0.0.1
```

**Fichier à créer**: `lib/services/secure_storage_service.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  
  // Stocker sensitive data (tokens, keys)
  static Future<void> saveToken(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  static Future<String?> getToken(String key) async {
    return await _storage.read(key: key);
  }
  
  static Future<void> deleteToken(String key) async {
    await _storage.delete(key: key);
  }
  
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

**Modifier**: `lib/services/verification_service.dart`

```dart
// ❌ AVANT
_otpBox.put(sanitizedPhone, {
  'otp': otp,
  'createdAt': DateTime.now().toIso8601String(),
  'attempts': 0,
});

// ✅ APRÈS
import 'package:encrypted_hive/encrypted_hive.dart';

// Dans init()
_otpBox = await EncryptedHive.openBox(
  _otpBoxName,
  encryptionCipher: HiveAesCipher(getEncryptionKey()),
);

// Générer clé une fois et la stocker sécurisée
static List<int> getEncryptionKey() {
  // Load from secure storage or generate once
  // IMPORTANT: Ne pas la hardcoder!
}
```

---

### 3. Implémenter JWT Tokens

**Fichier à créer**: `lib/services/auth_token_service.dart`

```dart
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthTokenService {
  static const _accessTokenExpiry = Duration(minutes: 15);
  static const _refreshTokenExpiry = Duration(days: 7);
  
  late String _jwtSecret; // À charger de secure storage
  
  /// Générer access token
  String generateAccessToken(String userId, String email) {
    final jwt = JWT({
      'userId': userId,
      'email': email,
      'iat': DateTime.now().millisecondsSinceEpoch,
      'exp': DateTime.now().add(_accessTokenExpiry).millisecondsSinceEpoch,
      'type': 'access',
    });
    return jwt.sign(SecretKey(_jwtSecret));
  }
  
  /// Générer refresh token
  String generateRefreshToken(String userId) {
    final jwt = JWT({
      'userId': userId,
      'iat': DateTime.now().millisecondsSinceEpoch,
      'exp': DateTime.now().add(_refreshTokenExpiry).millisecondsSinceEpoch,
      'type': 'refresh',
    });
    return jwt.sign(SecretKey(_jwtSecret));
  }
  
  /// Vérifier et décoder token
  bool verifyToken(String token) {
    try {
      JWT.verify(token, SecretKey(_jwtSecret));
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Récupérer user ID du token
  String? getUserIdFromToken(String token) {
    try {
      final decoded = JWT.decode(token);
      return decoded.payload['userId'] as String?;
    } catch (e) {
      return null;
    }
  }
}
```

**pubspec.yaml**:
```yaml
dependencies:
  dart_jsonwebtoken: ^2.12.0
```

---

### 4. Implémenter Firebase Auth Réelle

**Modifier**: `lib/providers/auth_provider.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_token_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _tokenService = AuthTokenService();
  
  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  
  /// Login avec email et password
  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      // Si c'est un téléphone, chercher email associé dans Firestore
      String email = emailOrPhone;
      if (emailOrPhone.contains(RegExp(r'^\+?\d'))) {
        // C'est un téléphone - récupérer email de Firestore
        // TODO: Query Firestore
      }
      
      final credentials = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _currentUser = credentials.user;
      
      // Générer tokens
      _accessToken = _tokenService.generateAccessToken(
        _currentUser!.uid,
        _currentUser!.email!,
      );
      _refreshToken = _tokenService.generateRefreshToken(_currentUser!.uid);
      
      // Sauvegarder tokens sécurisés
      await SecureStorageService.saveToken('access_token', _accessToken!);
      await SecureStorageService.saveToken('refresh_token', _refreshToken!);
      
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Utilisateur non trouvé');
      } else if (e.code == 'wrong-password') {
        throw Exception('Mot de passe incorrect');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email invalide');
      }
      rethrow;
    }
  }
  
  /// Inscription
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final credentials = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await credentials.user?.updateDisplayName(fullName);
      
      _currentUser = credentials.user;
      
      // Générer tokens
      _accessToken = _tokenService.generateAccessToken(
        _currentUser!.uid,
        email,
      );
      _refreshToken = _tokenService.generateRefreshToken(_currentUser!.uid);
      
      await SecureStorageService.saveToken('access_token', _accessToken!);
      await SecureStorageService.saveToken('refresh_token', _refreshToken!);
      
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Mot de passe trop faible');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Email déjà utilisé');
      }
      rethrow;
    }
  }
  
  /// Refresh token
  Future<bool> refreshAccessToken() async {
    try {
      final storedRefreshToken = await SecureStorageService.getToken('refresh_token');
      if (storedRefreshToken == null) return false;
      
      if (!_tokenService.verifyToken(storedRefreshToken)) {
        await logout();
        return false;
      }
      
      final userId = _tokenService.getUserIdFromToken(storedRefreshToken);
      if (userId == null) return false;
      
      _accessToken = _tokenService.generateAccessToken(userId, _currentUser!.email!);
      await SecureStorageService.saveToken('access_token', _accessToken!);
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
    await SecureStorageService.clearAll();
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
  }
  
  /// Vérifier token au démarrage
  Future<void> checkAuthStatus() async {
    final storedAccessToken = await SecureStorageService.getToken('access_token');
    if (storedAccessToken != null && _tokenService.verifyToken(storedAccessToken)) {
      _accessToken = storedAccessToken;
      _currentUser = _auth.currentUser;
      notifyListeners();
    }
  }
}
```

---

### 5. Sécuriser Génération OTP

**Modifier**: `lib/utils/security_utils.dart`

```dart
import 'dart:math';

// ❌ AVANT
static String generateOTP({int length = 6}) {
    final random = List<int>.generate(length, (i) => 48 + (i % 10));
    return String.fromCharCodes(random);
}

// ✅ APRÈS - Utiliser Random.secure()
static String generateOTP({int length = 6}) {
  final random = Random.secure();
  final values = List<int>.generate(length, (i) => random.nextInt(10));
  return values.join();
}
```

---

### 6. Configurer Firestore Security Rules

**Fichier**: `firestore.rules`

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Default: deny all
    match /{document=**} {
      allow read, write: if false;
    }
    
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      allow read: if request.auth.uid != null; // Autres users voir profil public
    }
    
    // Verification data - only owner can read
    match /verifications/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Products - public read, owner write
    match /products/{productId} {
      allow read: if request.auth.uid != null;
      allow write: if request.auth.uid == resource.data.ownerId;
      allow create: if request.auth.uid != null;
    }
    
    // Services - public read, owner write
    match /services/{serviceId} {
      allow read: if request.auth.uid != null;
      allow write: if request.auth.uid == resource.data.providerId;
      allow create: if request.auth.uid != null;
    }
    
    // Chat - participants only
    match /chats/{chatId} {
      allow read: if request.auth.uid in resource.data.participants;
      allow write: if request.auth.uid in resource.data.participants;
      
      match /messages/{messageId} {
        allow read: if request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        allow create: if request.auth.uid == request.resource.data.senderId;
      }
    }
    
    // Fraud reports - anonymous create, moderators view
    match /fraudReports/{reportId} {
      allow create: if request.auth.uid != null;
      allow read, write: if request.auth.token.isAdmin == true;
    }
    
    // Reviews - public read, author write
    match /reviews/{reviewId} {
      allow read: if true;
      allow write: if request.auth.uid == resource.data.reviewerId;
      allow create: if request.auth.uid != null;
    }
  }
}
```

---

## Phase 2: Améliorations HAUTES (2-3 Semaines)

### 7. Implémenter SMS Réel (Twilio)

**pubspec.yaml**:
```yaml
dependencies:
  twilio_flutter: ^0.0.9
```

**Fichier à créer**: `lib/services/sms_service.dart`

```dart
import 'package:twilio_flutter/twilio_flutter.dart';

class SmsService {
  late TwilioFlutter _twilio;
  
  SmsService() {
    _twilio = TwilioFlutter(
      accountSid: 'YOUR_ACCOUNT_SID', // À charger depuis .env
      authToken: 'YOUR_AUTH_TOKEN',
      twilioNumber: '+1234567890',
    );
  }
  
  Future<void> sendOTP(String phoneNumber, String otp) async {
    try {
      await _twilio.sendSMS(
        toNumber: phoneNumber,
        messageBody: 'Votre code OTP GabonConnect est: $otp (Valable 5 minutes)',
      );
    } catch (e) {
      debugPrint('Erreur envoi SMS: $e');
      rethrow;
    }
  }
}
```

---

### 8. Ajouter Tests Unitaires

**Fichier à créer**: `test/utils/security_utils_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gabon_connect/utils/security_utils.dart';

void main() {
  group('SecurityUtils', () {
    test('hashPassword should not return plaintext', () {
      final password = 'MyPassword123';
      final hash = SecurityUtils.hashPassword(password);
      expect(hash, isNotEmpty);
      expect(hash, isNot(password));
    });
    
    test('verifyPassword should match correct password', () {
      final password = 'MyPassword123';
      final hash = SecurityUtils.hashPassword(password);
      expect(SecurityUtils.verifyPassword(password, hash), isTrue);
    });
    
    test('verifyPassword should reject wrong password', () {
      final password = 'MyPassword123';
      final wrongPassword = 'WrongPassword';
      final hash = SecurityUtils.hashPassword(password);
      expect(SecurityUtils.verifyPassword(wrongPassword, hash), isFalse);
    });
    
    test('generateOTP should generate 6 digit string', () {
      final otp = SecurityUtils.generateOTP();
      expect(otp.length, 6);
      expect(int.tryParse(otp), isNotNull);
    });
    
    test('maskEmail should hide middle characters', () {
      final email = 'john.doe@example.com';
      final masked = SecurityUtils.maskEmail(email);
      expect(masked, contains('@example.com'));
      expect(masked, isNot(email));
    });
    
    test('isSafeInput should reject SQL injection', () {
      expect(
        SecurityValidator.isSafeInput("'; DROP TABLE users; --"),
        isFalse,
      );
    });
    
    test('isValidPhoneNumber should accept +241 format', () {
      expect(
        SecurityValidator.isValidPhoneNumber('+241612345678'),
        isTrue,
      );
    });
  });
}
```

---

### 9. Implémenter Certificate Pinning

**Fichier à créer**: `lib/services/http_client_service.dart`

```dart
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';

class HttpClientService {
  static HttpClient createHttpClient() {
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback = (
        X509Certificate cert,
        String host,
        int port,
      ) {
        // Implémenter pinning ici
        const allowedFingerprints = {
          'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // Your certificate fingerprint
        };
        
        // Calculer fingerprint du certificat et vérifier
        // ...
        return false; // Rejeter si pas d'accord
      };
    
    return httpClient;
  }
  
  static http.Client getClient() {
    return IOClient(createHttpClient());
  }
}
```

---

### 10. Ajouter Audit Logging

**Fichier à créer**: `lib/services/audit_log_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditAction {
  login,
  logout,
  passwordChange,
  phoneVerification,
  idVerification,
  transactionCreated,
  transactionCompleted,
  userReported,
  dataAccessed,
}

class AuditLogService {
  static final _firestore = FirebaseFirestore.instance;
  
  static Future<void> log({
    required String userId,
    required AuditAction action,
    required Map<String, dynamic> details,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      await _firestore.collection('audit_logs').add({
        'userId': userId,
        'action': action.toString(),
        'details': details,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      debugPrint('Erreur log audit: $e');
    }
  }
}
```

---

## Configuration .env (À Créer)

**Fichier**: `.env` (à ajouter à `.gitignore`)

```
# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
FIREBASE_MESSAGING_SENDER_ID=your-sender-id

# Twilio
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_PHONE_NUMBER=+1234567890

# JWT
JWT_SECRET=your-super-secret-key-minimum-32-chars

# API
API_BASE_URL=https://api.yourdomain.com
```

---

## Migration Database

Si migration depuis prototype:

```dart
// Migration du cache Hive non-encrypté vers encrypté
Future<void> migrateHiveToEncrypted() async {
  // 1. Lire données anciennes boxes
  final servicesBox = await Hive.openBox('services_cache');
  final productsBox = await Hive.openBox('products_cache');
  
  // 2. Créer encrypted boxes
  final encryptedServicesBox = await EncryptedHive.openBox(
    'services_cache_encrypted',
    encryptionCipher: HiveAesCipher(getEncryptionKey()),
  );
  
  // 3. Migrer données
  for (final key in servicesBox.keys) {
    await encryptedServicesBox.put(key, servicesBox.get(key));
  }
  
  // 4. Supprimer anciennes boxes
  await servicesBox.deleteFromDisk();
}
```

---

**Prochaine étape**: Implémenter corrections Phase 1 cette semaine!
