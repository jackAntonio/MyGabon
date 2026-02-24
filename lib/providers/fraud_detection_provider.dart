import 'package:flutter/material.dart';
import '../models/security_models.dart';
import '../services/fraud_detection_service.dart';

/// Provider for fraud detection and prevention
class FraudDetectionProvider extends ChangeNotifier {
  final FraudDetectionService _fraudService;
  
  FraudRiskLevel _currentRiskLevel = FraudRiskLevel.safe;
  List<FraudReport> _userReports = [];
  List<String> _userRiskFlags = [];
  bool _isAnalyzing = false;
  String? _error;
  
  FraudDetectionProvider(this._fraudService);
  
  // Getters
  FraudRiskLevel get currentRiskLevel => _currentRiskLevel;
  List<FraudReport> get userReports => _userReports;
  List<String> get userRiskFlags => _userRiskFlags;
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;
  
  bool get hasHighRisk => _currentRiskLevel == FraudRiskLevel.high || 
                          _currentRiskLevel == FraudRiskLevel.critical;
  
  String getRiskLevelText() {
    switch (_currentRiskLevel) {
      case FraudRiskLevel.safe:
        return 'Sûr';
      case FraudRiskLevel.low:
        return 'Faible risque';
      case FraudRiskLevel.moderate:
        return 'Risque modéré';
      case FraudRiskLevel.high:
        return 'Risque élevé';
      case FraudRiskLevel.critical:
        return 'Risque critique';
    }
  }
  
  Color getRiskLevelColor() {
    switch (_currentRiskLevel) {
      case FraudRiskLevel.safe:
        return Colors.green;
      case FraudRiskLevel.low:
        return Colors.lightGreen;
      case FraudRiskLevel.moderate:
        return Colors.orange;
      case FraudRiskLevel.high:
        return Colors.deepOrange;
      case FraudRiskLevel.critical:
        return Colors.red;
    }
  }
  
  /// Analyze transaction for fraud
  Future<void> analyzeTransaction({
    required String userId,
    required String transactionType,
    required double amount,
    required String? recipientId,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      _isAnalyzing = true;
      _error = null;
      notifyListeners();
      
      _currentRiskLevel = await _fraudService.analyzeTransaction(
        userId: userId,
        transactionType: transactionType,
        amount: amount,
        recipientId: recipientId,
        metadata: metadata,
      );
      
      // Load user risk flags
      _userRiskFlags = await _fraudService.getUserRiskFlags(userId);
      
      _isAnalyzing = false;
      notifyListeners();
    } catch (e) {
      _isAnalyzing = false;
      _error = 'Failed to analyze transaction';
      notifyListeners();
    }
  }
  
  /// Report suspicious activity
  Future<bool> reportSuspiciousActivity({
    required String reporterId,
    required String suspiciousUserId,
    required String reason,
    required String description,
    String? listingId,
    List<String>? evidenceUrls,
  }) async {
    try {
      _isAnalyzing = true;
      _error = null;
      notifyListeners();
      
      await _fraudService.reportSuspiciousActivity(
        reporterId: reporterId,
        suspiciousUserId: suspiciousUserId,
        reason: reason,
        description: description,
        listingId: listingId,
        evidenceUrls: evidenceUrls,
      );
      
      // Reload user reports
      _userReports = await _fraudService.getUserReports(suspiciousUserId);
      
      // Reload risk flags
      _userRiskFlags = await _fraudService.getUserRiskFlags(suspiciousUserId);
      
      _isAnalyzing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isAnalyzing = false;
      _error = 'Failed to report suspicious activity';
      notifyListeners();
      return false;
    }
  }
  
  /// Load fraud reports for user
  Future<void> loadUserReports(String userId) async {
    try {
      _isAnalyzing = true;
      _error = null;
      notifyListeners();
      
      _userReports = await _fraudService.getUserReports(userId);
      _userRiskFlags = await _fraudService.getUserRiskFlags(userId);
      
      _isAnalyzing = false;
      notifyListeners();
    } catch (e) {
      _isAnalyzing = false;
      _error = 'Failed to load fraud reports';
      notifyListeners();
    }
  }
  
  /// Block user
  Future<bool> blockUser(String userId, String reason) async {
    try {
      _isAnalyzing = true;
      _error = null;
      notifyListeners();
      
      await _fraudService.blockUser(userId, reason);
      
      _userRiskFlags = await _fraudService.getUserRiskFlags(userId);
      
      _isAnalyzing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isAnalyzing = false;
      _error = 'Failed to block user';
      notifyListeners();
      return false;
    }
  }
  
  /// Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      return await _fraudService.isUserBlocked(userId);
    } catch (e) {
      return false;
    }
  }
  
  /// Get fraud statistics
  Future<Map<String, dynamic>> getFraudStats() async {
    try {
      return await _fraudService.getFraudStats();
    } catch (e) {
      return {};
    }
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
