import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ✅ Service d'audit logging pour tracer actions sensibles
/// Enregistre les actions de sécurité dans Firestore
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

class AuditLog {
  final String id;
  final String userId;
  final AuditAction action;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final String status; // 'success', 'failure'
  final String? errorMessage;
  
  AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.details,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.status = 'success',
    this.errorMessage,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'action': action.toString(),
    'details': details,
    'timestamp': timestamp.toIso8601String(),
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'status': status,
    'errorMessage': errorMessage,
  };
  
  static AuditLog fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      userId: json['userId'] as String,
      action: AuditAction.values.firstWhere(
        (e) => e.toString() == json['action'],
        orElse: () => AuditAction.dataAccessed,
      ),
      details: json['details'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.parse(json['timestamp'] as String),
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      status: json['status'] as String? ?? 'success',
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();
  
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  
  static const String _collectionName = 'auditLogs';
  
  factory AuditLogService() {
    return _instance;
  }
  
  AuditLogService._internal() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
  }
  
  /// Logger une action sensible
  Future<void> log({
    required AuditAction action,
    required Map<String, dynamic> details,
    String? ipAddress,
    String? userAgent,
    String status = 'success',
    String? errorMessage,
  }) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      
      final auditLog = AuditLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        action: action,
        details: details,
        timestamp: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
        status: status,
        errorMessage: errorMessage,
      );
      
      await _firestore
          .collection(_collectionName)
          .doc(auditLog.id)
          .set(auditLog.toJson());
      
      debugPrint('✅ Audit log: $action pour $userId');
    } catch (e) {
      debugPrint('❌ Erreur logging audit: $e');
    }
  }
  
  /// Logger login
  Future<void> logLogin({
    required String email,
    String? ipAddress,
    bool success = true,
  }) async {
    await log(
      action: AuditAction.login,
      details: {'email': email},
      ipAddress: ipAddress,
      status: success ? 'success' : 'failure',
    );
  }
  
  /// Logger logout
  Future<void> logLogout() async {
    await log(
      action: AuditAction.logout,
      details: {},
    );
  }
  
  /// Logger changement de mot de passe
  Future<void> logPasswordChange() async {
    await log(
      action: AuditAction.passwordChange,
      details: {},
    );
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
      details: {
        'idType': idType,
        'verified': verified,
      },
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
      details: {
        'paymentId': paymentId,
        'amount': amount,
        'method': method,
      },
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
      details: {
        'reason': reason,
        ...details,
      },
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
  Future<List<AuditLog>> getUserAuditLogs(String userId, {int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => AuditLog.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération logs: $e');
      return [];
    }
  }
  
  /// Récupérer logs par action
  Future<List<AuditLog>> getLogsByAction(AuditAction action, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('action', isEqualTo: action.toString())
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => AuditLog.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération logs: $e');
      return [];
    }
  }
  
  /// Récupérer logs récents (dernières 24h)
  Future<List<AuditLog>> getRecentLogs({int limit = 100}) async {
    try {
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('timestamp', isGreaterThanOrEqualTo: oneDayAgo.toIso8601String())
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => AuditLog.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération logs récents: $e');
      return [];
    }
  }
  
  /// Récupérer logs d'activité suspecte
  Future<List<AuditLog>> getSuspiciousActivityLogs({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('action', isEqualTo: AuditAction.suspiciousActivityDetected.toString())
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => AuditLog.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération logs suspects: $e');
      return [];
    }
  }
  
  /// Helper: masquer numéro de téléphone pour logs
  static String _maskPhoneNumber(String phone) {
    if (phone.length < 4) return '****';
    return '*' * (phone.length - 4) + phone.substring(phone.length - 4);
  }
}
