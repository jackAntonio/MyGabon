# 📚 GUIDE D'INTÉGRATION PHASE 2

## 📌 Vue d'Ensemble des Services

| Service | Fichier | Utilité |
|---------|---------|---------|
| **AuditLogService** | `audit_log_service.dart` | Logger actions sensibles |
| **SmsService** | `sms_service.dart` | Envoyer SMS/OTP |
| **HttpClientService** | `http_client_service.dart` | Requêtes HTTP sécurisées |
| **NotificationService** | `notification_service.dart` | Notifications push FCM |
| **AppServices** | `app_services.dart` | Initialisation globale |

---

## 🚀 ÉTAPE 1: Initialiser Services dans main.dart

### Modifier `lib/main.dart`

```dart
import 'app_services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Charger .env
  await dotenv.load();
  
  // Initialize cache
  await CacheService.init();
  
  // Initialize security services
  await VerificationService().init();
  await ReviewService().init();
  await FraudDetectionService().init();
  
  // ✅ Initialiser services Phase 2
  await AppServices().init(
    twilioAccountSid: dotenv.env['TWILIO_ACCOUNT_SID'] ?? '',
    twilioAuthToken: dotenv.env['TWILIO_AUTH_TOKEN'] ?? '',
    twilioPhoneNumber: dotenv.env['TWILIO_PHONE_NUMBER'] ?? '',
  );
  
  runApp(const GabonConnectApp());
}
```

---

## 🔐 ÉTAPE 2: Intégrer Audit Logging dans AuthProvider

### Modifier `lib/providers/auth_provider.dart`

```dart
import '../app_services.dart';

class AuthProvider extends ChangeNotifier {
  // ... existing code ...
  
  /// ✅ Login avec audit logging
  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      // ... Firebase login logic ...
      
      // ✅ Logger le login
      await auditLog.logLogin(
        email: email,
        success: true,
      );
      
      notifyListeners();
    } catch (e) {
      // ✅ Logger l'erreur
      await auditLog.logLogin(
        email: email,
        success: false,
      );
      _setError('Erreur authentification: ${e.toString()}');
    }
  }
  
  /// ✅ Logout avec audit logging
  Future<void> logout() async {
    try {
      // ✅ Logger logout avant suppression données
      await auditLog.logLogout();
      
      // ... logout logic ...
    } catch (e) {
      debugPrint('❌ Erreur logout: $e');
    }
  }
  
  /// ✅ Password reset avec audit logging
  Future<void> resetPassword({required String email}) async {
    try {
      // ... reset logic ...
      
      // ✅ Logger password reset
      await auditLog.log(
        action: AuditAction.passwordReset,
        details: {'email': email},
      );
    } catch (e) {
      // Logger erreur
      await auditLog.log(
        action: AuditAction.passwordReset,
        details: {'email': email},
        status: 'failure',
        errorMessage: e.toString(),
      );
    }
  }
}
```

---

## 📱 ÉTAPE 3: Intégrer SMS dans VerificationProvider

### Modifier `lib/providers/verification_provider.dart`

```dart
import '../app_services.dart';
import '../services/sms_service.dart';

class VerificationProvider extends ChangeNotifier {
  // ... existing code ...
  
  /// ✅ Envoyer OTP par SMS
  Future<String?> sendPhoneOTP(String phoneNumber) async {
    try {
      final otp = SecurityUtils.generateOTP();
      
      // ✅ Envoyer SMS
      final sent = await sms.sendOTP(
        phoneNumber: phoneNumber,
        otp: otp,
      );
      
      if (!sent) {
        throw Exception('Erreur envoi SMS');
      }
      
      // Sauvegarder OTP localement
      await _verificationService.sendOTPToPhone(phoneNumber);
      
      // ✅ Logger vérification
      await auditLog.logPhoneVerification(
        phoneNumber: phoneNumber,
        verified: true,
      );
      
      return 'OTP_SENT';
    } catch (e) {
      debugPrint('❌ Erreur envoi OTP: $e');
      
      // ✅ Logger erreur
      await auditLog.log(
        action: AuditAction.phoneVerification,
        details: {'phoneNumber': phoneNumber},
        status: 'failure',
        errorMessage: e.toString(),
      );
      
      return null;
    }
  }
}
```

---

## 🔔 ÉTAPE 4: Intégrer FCM Notifications

### Modifier `lib/providers/chat_provider.dart` (Exemple)

```dart
import '../app_services.dart';

class ChatProvider extends ChangeNotifier {
  // ... existing code ...
  
  /// ✅ Envoyer message avec notification
  Future<void> sendMessage(String chatId, String message) async {
    try {
      // Envoyer message à Firestore
      // await _sendToFirestore(chatId, message);
      
      // ✅ Envoyer notification au recipient
      // Note: Nécessite backend pour envoyer via FCM
      // await _notifyRecipient(chatId, message);
      
      // Logger dans audit
      await auditLog.log(
        action: AuditAction.dataAccessed,
        details: {
          'type': 'message',
          'chatId': chatId,
          'hasAttachment': false,
        },
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur envoi message: $e');
    }
  }
}
```

---

## 💳 ÉTAPE 5: Intégrer Audit Logging pour Transactions

### Créer `lib/providers/transaction_provider.dart`

```dart
import '../app_services.dart';
import 'dart:async';

class TransactionProvider extends ChangeNotifier {
  
  /// ✅ Logger création transaction
  Future<void> createTransaction({
    required String type,
    required double amount,
    required String recipientId,
  }) async {
    try {
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Créer transaction...
      
      // ✅ Logger la transaction
      await auditLog.logTransaction(
        transactionId: transactionId,
        type: type,
        amount: amount,
        status: 'pending',
      );
      
      notifyListeners();
    } catch (e) {
      // Logger erreur
      await auditLog.log(
        action: AuditAction.transactionCreated,
        details: {'type': type, 'amount': amount},
        status: 'failure',
        errorMessage: e.toString(),
      );
    }
  }
  
  /// ✅ Logger paiement
  Future<void> processPayment({
    required String paymentId,
    required double amount,
    required String method,
  }) async {
    try {
      // Traiter paiement...
      
      // ✅ Logger le paiement
      await auditLog.logPayment(
        paymentId: paymentId,
        amount: amount,
        method: method,
        success: true,
      );
    } catch (e) {
      // Logger erreur
      await auditLog.logPayment(
        paymentId: paymentId,
        amount: amount,
        method: method,
        success: false,
      );
    }
  }
}
```

---

## 🚨 ÉTAPE 6: Logger Activité Suspecte dans FraudDetection

### Modifier `lib/services/fraud_detection_service.dart`

```dart
import '../app_services.dart';

class FraudDetectionService {
  
  /// ✅ Analyser transaction et logger si suspecte
  Future<FraudRiskLevel> analyzeTransaction({
    required String userId,
    required double amount,
    // ... other params
  }) async {
    var riskScore = 0.0;
    
    // ... existing analysis logic ...
    
    final riskLevel = _calculateRiskLevel(riskScore);
    
    // ✅ Logger si activité suspecte
    if (riskScore >= 0.6) {
      await auditLog.logSuspiciousActivity(
        reason: 'Transaction à risque détectée',
        details: {
          'userId': userId,
          'amount': amount,
          'riskScore': riskScore,
          'riskLevel': riskLevel.toString(),
        },
      );
    }
    
    return riskLevel;
  }
}
```

---

## 📡 ÉTAPE 7: Utiliser HTTP Client Sécurisé

### Exemple d'utilisation dans un provider

```dart
import '../app_services.dart';
import 'dart:convert';

class ApiProvider extends ChangeNotifier {
  
  /// ✅ Appel API sécurisé
  Future<Map<String, dynamic>> fetchUserData(String userId) async {
    try {
      final token = _getAuthToken();
      
      final response = await httpClient.get(
        Uri.parse('https://api.yourdomain.com/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // ✅ Logger accès données
        await auditLog.log(
          action: AuditAction.dataAccessed,
          details: {'resource': 'user/$userId'},
        );
        
        return data;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur API: $e');
      rethrow;
    }
  }
}
```

---

## ✅ CHECKLIST D'INTÉGRATION

### Dans main.dart:
- [ ] Importer `AppServices`
- [ ] Importer `flutter_dotenv`
- [ ] Charger `.env` file
- [ ] Initialiser `AppServices`
- [ ] Vérifier tous les services démarent

### Dans AuthProvider:
- [ ] Logger login success/failure
- [ ] Logger logout
- [ ] Logger password reset

### Dans VerificationProvider:
- [ ] Utiliser `sms.sendOTP()`
- [ ] Logger phone verification
- [ ] Logger ID verification

### Dans ChatProvider:
- [ ] Logger messages envoyés
- [ ] S'abonner à notifications

### Dans FraudDetectionService:
- [ ] Logger activité suspecte
- [ ] Logger transactions à risque

### Dans ApiProvider:
- [ ] Utiliser `httpClient` pour requêtes
- [ ] Logger accès données sensibles

### Général:
- [ ] Tester sur device physique
- [ ] Vérifier logs dans Firestore
- [ ] Vérifier SMS reçus (Twilio)
- [ ] Vérifier notifications (FCM)

---

## 🧪 TESTER INTÉGRATION

```bash
# 1. Tester compilation
flutter clean
flutter pub get
flutter analyze

# 2. Tester sur émulateur
flutter run

# 3. Tester SMS
# - Aller à Login
# - Entrer téléphone
# - Vérifier SMS reçu (ou logs Twilio)

# 4. Vérifier Audit Logs
# - Ouvrir Firebase Console
# - Vérifier collection 'auditLogs'
# - Voir les logs des actions

# 5. Tests unitaires
flutter test test/integration_tests.dart

# 6. Couverture
flutter test --coverage
```

---

## 🔗 FLUX COMPLET D'AUTHENTIFICATION AVEC LOGS

```
1. Utilisateur clique "Login"
2. → AuditLogService.logLogin(email, success=false)

3. Entre email + password
4. → Firebase Auth verification
5. → AuditLogService.logLogin(email, success=true)

6. Clique "Verify Phone"
7. → SmsService.sendOTP(phone, otp)
8. → AuditLogService.logPhoneVerification(phone, verified=true)

9. Reçoit SMS avec OTP
10. → Entre OTP
11. → VerificationService.verifyOTP()
12. → AuditLogService.logPhoneVerification(phone, verified=true)

13. Login Complet!
14. → Tous les logs visibles dans Firestore
15. → Admins peuvent consulter dans dashboard
```

---

## 📊 MONITORING AUDIT LOGS

Pour vérifier que tout fonctionne:

```dart
// Dans DevTools/Console
final auditService = AuditLogService();

// Récupérer logs récents
final logs = await auditService.getRecentLogs(limit: 20);

// Afficher
logs.forEach((log) {
  print('${log.timestamp}: ${log.action} - ${log.status}');
});
```

---

## ⚠️ POINTS IMPORTANTS

1. **Configuration .env Required**: Sans cela, SMS ne fonctionnera pas
2. **Firebase Firestore Active**: Pour audit logs
3. **FCM Setup**: Pour notifications
4. **Certificat Domain**: Pour certificate pinning
5. **Tests**: Tester en staging avant production

---

**Status**: Guide complet pour Phase 2  
**Utilisez ce guide pour intégration étape par étape**
