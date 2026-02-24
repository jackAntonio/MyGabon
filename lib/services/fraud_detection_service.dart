import 'dart:async';
import 'package:hive/hive.dart';
import '../models/security_models.dart';
import '../utils/security_utils.dart';

/// Service for fraud detection and prevention
class FraudDetectionService {
  static const String _reportsBoxName = 'fraud_reports';
  static const String _suspiciousBoxName = 'suspicious_activity';
  
  late Box<dynamic> _reportsBox;
  late Box<dynamic> _suspiciousBox;
  
  static final FraudDetectionService _instance = FraudDetectionService._internal();
  
  factory FraudDetectionService() {
    return _instance;
  }
  
  FraudDetectionService._internal();
  
  /// Initialize Hive boxes
  Future<void> init() async {
    _reportsBox = await Hive.openBox(_reportsBoxName);
    _suspiciousBox = await Hive.openBox(_suspiciousBoxName);
  }
  
  /// Analyze transaction for fraud risk
  Future<FraudRiskLevel> analyzeTransaction({
    required String userId,
    required String transactionType,
    required double amount,
    required String? recipientId,
    required Map<String, dynamic> metadata,
  }) async {
    var riskScore = 0.0;
    
    // Check if user is new (created < 7 days)
    if (metadata['accountAge'] is int) {
      final accountAgeDays = metadata['accountAge'] as int;
      if (accountAgeDays < 7) {
        riskScore += 0.3;  // 30 points
      }
    }
    
    // Check amount anomaly
    if (metadata['previousAverageAmount'] is double) {
      final avgAmount = metadata['previousAverageAmount'] as double;
      final ratio = amount / (avgAmount > 0 ? avgAmount : 1);
      if (ratio > 5) {  // 5x normal amount
        riskScore += 0.2;  // 20 points
      }
    }
    
    // Check frequency anomaly
    if (metadata['transactionFrequency'] is int) {
      final frequency = metadata['transactionFrequency'] as int;
      if (frequency > 10) {  // More than 10 transactions in last hour
        riskScore += 0.25;
      }
    }
    
    // Check for suspicious keywords
    if (metadata['description'] is String) {
      if (SecurityValidator.isSuspiciousActivity(metadata['description'])) {
        riskScore += 0.15;
      }
    }
    
    // Check if recipient is flagged
    if (recipientId != null && await _isUserFlagged(recipientId)) {
      riskScore += 0.2;
    }
    
    // Check if user has multiple reports
    final userReports = await getUserReports(userId);
    if (userReports.length > 2) {
      riskScore += 0.15;
    }
    
    // Convert score to risk level
    if (riskScore >= 0.8) return FraudRiskLevel.critical;
    if (riskScore >= 0.6) return FraudRiskLevel.high;
    if (riskScore >= 0.4) return FraudRiskLevel.moderate;
    if (riskScore >= 0.2) return FraudRiskLevel.low;
    return FraudRiskLevel.safe;
  }
  
  /// Report suspicious user/listing
  Future<String> reportSuspiciousActivity({
    required String reporterId,
    required String suspiciousUserId,
    required String reason,
    required String description,
    String? listingId,
    List<String>? evidenceUrls,
  }) async {
    if (!SecurityValidator.isSafeInput(description)) {
      throw Exception('Invalid report description');
    }
    
    final report = FraudReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reporterId: reporterId,
      suspiciousUserId: suspiciousUserId,
      listingId: listingId,
      reportReason: reason,
      description: description,
      evidence: evidenceUrls ?? [],
    );
    
    _reportsBox.put(report.id, report.toJson());
    
    // Flag user if multiple reports
    final userReports = await getUserReports(suspiciousUserId);
    if (userReports.length >= 3) {
      await _flagUser(suspiciousUserId, 'Multiple fraud reports');
    }
    
    return report.id;
  }
  
  /// Get fraud reports for a user
  Future<List<FraudReport>> getUserReports(String userId) async {
    final reports = <FraudReport>[];
    
    for (final data in _reportsBox.values) {
      if (data is Map) {
        final report = data as Map<String, dynamic>;
        if (report['suspiciousUserId'] == userId) {
          reports.add(FraudReport(
            id: report['id'],
            reporterId: report['reporterId'],
            suspiciousUserId: report['suspiciousUserId'],
            listingId: report['listingId'],
            reportReason: report['reportReason'],
            description: report['description'],
            evidence: List<String>.from(report['evidence'] ?? []),
            verified: report['verified'] ?? false,
          ));
        }
      }
    }
    
    return reports;
  }
  
  /// Flag user as suspicious
  Future<void> _flagUser(String userId, String reason) async {
    _suspiciousBox.put(userId, {
      'userId': userId,
      'flaggedAt': DateTime.now().toIso8601String(),
      'reason': reason,
      'severity': 'high',
    });
  }
  
  /// Check if user is flagged
  Future<bool> _isUserFlagged(String userId) async {
    return _suspiciousBox.containsKey(userId);
  }
  
  /// Get suspicious users
  Future<List<String>> getSuspiciousUsers() async {
    return List<String>.from(_suspiciousBox.keys.cast<String>());
  }
  
  /// Get fraud stats
  Future<Map<String, dynamic>> getFraudStats() async {
    final totalReports = _reportsBox.length;
    final verifiedReports = _reportsBox.values
        .whereType<Map>()
        .where((v) => v['verified'] == true)
        .length;
    final suspiciousUserCount = _suspiciousBox.length;
    
    return {
      'totalReports': totalReports,
      'verifiedReports': verifiedReports,
      'suspiciousUsers': suspiciousUserCount,
      'lastUpdate': DateTime.now().toIso8601String(),
    };
  }
  
  /// Verify fraud report (by moderator)
  Future<void> verifyReport(String reportId) async {
    if (_reportsBox.containsKey(reportId)) {
      final data = _reportsBox.get(reportId) as Map;
      data['verified'] = true;
      _reportsBox.put(reportId, data);
    }
  }
  
  /// Block user
  Future<void> blockUser(String userId, String reason) async {
    _suspiciousBox.put('blocked_$userId', {
      'userId': userId,
      'blockedAt': DateTime.now().toIso8601String(),
      'reason': reason,
      'severity': 'critical',
      'blocked': true,
    });
  }
  
  /// Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    return _suspiciousBox.containsKey('blocked_$userId');
  }
  
  /// Cleanup old reports
  Future<void> cleanupOldReports({int daysOld = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    final keysToRemove = <String>[];
    for (final entry in _reportsBox.toMap().entries) {
      if (entry.value is Map) {
        final data = entry.value as Map;
        if (data['createdAt'] != null) {
          final createdAt = DateTime.parse(data['createdAt']);
          if (createdAt.isBefore(cutoffDate)) {
            keysToRemove.add(entry.key);
          }
        }
      }
    }
    
    for (final key in keysToRemove) {
      _reportsBox.delete(key);
    }
  }
  
  /// Get risk flags for user
  Future<List<String>> getUserRiskFlags(String userId) async {
    final flags = <String>[];
    
    // Check if user has many reports
    final reports = await getUserReports(userId);
    if (reports.length > 2) {
      flags.add('Multiple fraud reports (${reports.length})');
    }
    
    // Check if flagged
    if (await _isUserFlagged(userId)) {
      flags.add('Account flagged as suspicious');
    }
    
    // Check if blocked
    if (await isUserBlocked(userId)) {
      flags.add('Account blocked');
    }
    
    return flags;
  }
}
