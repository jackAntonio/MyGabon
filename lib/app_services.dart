import 'package:flutter/foundation.dart';
import 'services/audit_log_service.dart';
import 'services/sms_service.dart';
import 'services/http_client_service.dart';
import 'services/notification_service.dart';

/// ✅ Singleton pour accéder à tous les services globalement
class AppServices {
  static final AppServices _instance = AppServices._internal();
  
  late final AuditLogService auditLog;
  late final SmsService sms;
  late final HttpClientService httpClient;
  late final NotificationService notifications;
  
  factory AppServices() {
    return _instance;
  }
  
  AppServices._internal();
  
  /// Initialiser tous les services (appeler dans main())
  Future<void> init({
    required String twilioAccountSid,
    required String twilioAuthToken,
    required String twilioPhoneNumber,
  }) async {
    try {
      debugPrint('⚙️ Initialisation des services globaux...');
      
      // Audit Log Service
      auditLog = AuditLogService();
      debugPrint('✅ AuditLogService initialisé');
      
      // SMS Service
      sms = SmsService(
        accountSid: twilioAccountSid,
        authToken: twilioAuthToken,
        twilioNumber: twilioPhoneNumber,
      );
      debugPrint('✅ SmsService initialisé');
      
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
SmsService get sms => AppServices().sms;
HttpClientService get httpClient => AppServices().httpClient;
NotificationService get notifications => AppServices().notifications;
