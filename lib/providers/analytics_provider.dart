import 'package:flutter/material.dart';
import '../models/analytics_models.dart';
import '../services/analytics_service.dart';

/// Provider for analytics tracking and display
class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService;
  
  AnalyticsSummary? _userAnalytics;
  Map<String, dynamic> _platformStats = {};
  bool _isLoading = false;
  String? _error;
  
  AnalyticsProvider(this._analyticsService);
  
  // Getters
  AnalyticsSummary? get userAnalytics => _userAnalytics;
  Map<String, dynamic> get platformStats => _platformStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Load user analytics
  Future<void> loadUserAnalytics(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _userAnalytics = await _analyticsService.getUserAnalytics(
        userId,
        startDate: startDate,
        endDate: endDate,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load user analytics';
      notifyListeners();
    }
  }
  
  /// Load platform statistics
  Future<void> loadPlatformStats() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _platformStats = await _analyticsService.getPlatformStats();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load platform statistics';
      notifyListeners();
    }
  }
  
  /// Track engagement event
  Future<void> trackEngagement({
    required String userId,
    required String eventType,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _analyticsService.trackEngagement(
        userId: userId,
        eventType: eventType,
        targetId: targetId,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('Failed to track engagement: $e');
    }
  }
  
  /// Track conversion event
  Future<void> trackConversion({
    required String userId,
    required String conversionType,
    required double revenue,
    String? relatedUserId,
    String? promoCodeUsed,
  }) async {
    try {
      await _analyticsService.trackConversion(
        userId: userId,
        conversionType: conversionType,
        revenue: revenue,
        relatedUserId: relatedUserId,
        promoCodeUsed: promoCodeUsed,
      );
      
      // Reload user analytics
      await loadUserAnalytics(userId);
    } catch (e) {
      debugPrint('Failed to track conversion: $e');
    }
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
