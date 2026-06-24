import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// ✅ Service d'audit logging pour tracer les actions sensibles.
/// Persiste dans la table Supabase `audit_logs` (RLS : chaque utilisateur ne
/// lit que ses propres logs) via SupabaseService.logAuditEvent.
enum AuditAction {
  login,
  logout,
  passwordChange,
  passwordReset,
  phoneVerification,
  idVerification,
  transactionCreated,
  transactionCompleted,
  paymentProcessed,
  userReported,
  dataAccessed,
  adminActionPerformed,
  tokenGenerated,
  tokenRefreshed,
  suspiciousActivityDetected,
}

class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();

  final SupabaseService _service = SupabaseService();

  factory AuditLogService() {
    return _instance;
  }

  AuditLogService._internal();

  /// Logger une action sensible
  Future<void> log({
    required AuditAction action,
    required Map<String, dynamic> details,
    String status = 'success',
    String? errorMessage,
  }) async {
    try {
      await _service.logAuditEvent(
        action: action.name,
        details: {
          ...details,
          'status': status,
          if (errorMessage != null) 'errorMessage': errorMessage,
        },
      );
    } catch (e) {
      debugPrint('❌ Erreur logging audit: $e');
    }
  }

  /// Logger login
  Future<void> logLogin({
    required String email,
    bool success = true,
  }) async {
    await log(
      action: AuditAction.login,
      details: {'email': email},
      status: success ? 'success' : 'failure',
    );
  }

  /// Logger logout
  Future<void> logLogout() async {
    await log(action: AuditAction.logout, details: {});
  }

  /// Logger changement de mot de passe
  Future<void> logPasswordChange() async {
    await log(action: AuditAction.passwordChange, details: {});
  }

  /// Logger vérification de téléphone
  Future<void> logPhoneVerification({
    required String phoneNumber,
    required bool verified,
  }) async {
    await log(
      action: AuditAction.phoneVerification,
      details: {
        'phoneNumber': _maskPhoneNumber(phoneNumber),
        'verified': verified,
      },
    );
  }

  /// Logger vérification d'ID
  Future<void> logIdVerification({
    required String idType,
    required bool verified,
  }) async {
    await log(
      action: AuditAction.idVerification,
      details: {'idType': idType, 'verified': verified},
    );
  }

  /// Logger transaction
  Future<void> logTransaction({
    required String transactionId,
    required String type,
    required double amount,
    required String status,
  }) async {
    await log(
      action: AuditAction.transactionCreated,
      details: {
        'transactionId': transactionId,
        'type': type,
        'amount': amount,
        'status': status,
      },
    );
  }

  /// Logger paiement
  Future<void> logPayment({
    required String paymentId,
    required double amount,
    required String method,
    required bool success,
  }) async {
    await log(
      action: AuditAction.paymentProcessed,
      details: {'paymentId': paymentId, 'amount': amount, 'method': method},
      status: success ? 'success' : 'failure',
    );
  }

  /// Logger activité suspecte
  Future<void> logSuspiciousActivity({
    required String reason,
    required Map<String, dynamic> details,
  }) async {
    await log(
      action: AuditAction.suspiciousActivityDetected,
      details: {'reason': reason, ...details},
      status: 'warning',
    );
  }

  /// Logger action admin
  Future<void> logAdminAction({
    required String actionType,
    required String targetUserId,
    required Map<String, dynamic> details,
  }) async {
    await log(
      action: AuditAction.adminActionPerformed,
      details: {
        'actionType': actionType,
        'targetUserId': targetUserId,
        ...details,
      },
    );
  }

  /// Récupérer logs pour un utilisateur
  Future<List<Map<String, dynamic>>> getUserAuditLogs(
    String userId, {
    int limit = 100,
  }) async {
    return _service.getAuditLogs(userId: userId, limit: limit);
  }

  /// Helper: masquer numéro de téléphone pour logs
  static String _maskPhoneNumber(String phone) {
    if (phone.length < 4) return '****';
    return '*' * (phone.length - 4) + phone.substring(phone.length - 4);
  }
}
