import 'package:flutter/foundation.dart';
import 'services/audit_log_service.dart';
import 'services/http_client_service.dart';
import 'services/notification_service.dart';

/// ✅ Singleton pour accéder à tous les services globalement
/// L'envoi d'OTP par SMS ne passe plus par un service côté client (cf.
/// supabase/functions/send-otp-sms) : les credentials Twilio ne doivent
/// jamais être compilés dans l'app (extractibles d'un APK/IPA).
class AppServices {
  static final AppServices _instance = AppServices._internal();

  late final AuditLogService auditLog;
  late final HttpClientService httpClient;
  late final NotificationService notifications;

  factory AppServices() {
    return _instance;
  }

  AppServices._internal();

  /// Initialiser tous les services (appeler dans main())
  Future<void> init() async {
    try {
      debugPrint('⚙️ Initialisation des services globaux...');

      // Audit Log Service
      auditLog = AuditLogService();
      debugPrint('✅ AuditLogService initialisé');

      // HTTP Client Service
      httpClient = HttpClientService();
      debugPrint('✅ HttpClientService initialisé');

      // Notification Service
      notifications = NotificationService();
      await notifications.init();
      debugPrint('✅ NotificationService initialisé');

      debugPrint('✅ Tous les services initialisés avec succès');
    } catch (e) {
      debugPrint('❌ Erreur initialisation services: $e');
      rethrow;
    }
  }
}

/// Getters raccourcis pour accéder aux services
AuditLogService get auditLog => AppServices().auditLog;
HttpClientService get httpClient => AppServices().httpClient;
NotificationService get notifications => AppServices().notifications;
