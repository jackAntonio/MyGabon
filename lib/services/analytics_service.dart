import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/analytics_models.dart';
import '../utils/secure_hive.dart';

/// Service for tracking analytics events
class AnalyticsService {
  static const String _engagementBoxName = 'engagement_metrics';
  static const String _conversionBoxName = 'conversion_metrics';
  static const String _revenueBoxName = 'revenue_metrics';

  late Box<dynamic> _engagementBox;
  late Box<dynamic> _conversionBox;
  late Box<dynamic> _revenueBox;

  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  /// Initialize Hive boxes
  Future<void> init() async {
    _engagementBox = await SecureHive.openEncryptedBox(_engagementBoxName);
    _conversionBox = await SecureHive.openEncryptedBox(_conversionBoxName);
    _revenueBox = await SecureHive.openEncryptedBox(_revenueBoxName);
  }

  /// Track engagement event
  Future<void> trackEngagement({
    required String userId,
    required String eventType,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    final metric = EngagementMetric(
      id: const Uuid().v4(),
      userId: userId,
      eventType: eventType,
      targetId: targetId,
      metadata: metadata,
    );

    _engagementBox.put(metric.id, metric.toJson());
  }

  /// Track conversion event
  Future<void> trackConversion({
    required String userId,
    required String conversionType,
    required double revenue,
    String? relatedUserId,
    String? promoCodeUsed,
  }) async {
    final metric = ConversionMetric(
      id: const Uuid().v4(),
      userId: userId,
      conversionType: conversionType,
      revenue: revenue,
      relatedUserId: relatedUserId,
      promoCodeUsed: promoCodeUsed,
    );

    _conversionBox.put(metric.id, metric.toJson());

    // Also record as revenue metric
    await trackRevenue(
      source: conversionType,
      amount: revenue,
      userId: userId,
    );
  }

  /// Track revenue event
  Future<void> trackRevenue({
    required String source,
    required double amount,
    String? userId,
  }) async {
    final metric = RevenueMetric(
      id: const Uuid().v4(),
      source: source,
      amount: amount,
      userId: userId,
    );

    _revenueBox.put(metric.id, metric.toJson());
  }

  /// Get engagement metrics for user
  Future<AnalyticsSummary> getUserAnalytics(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    int totalViews = 0;
    int totalClicks = 0;
    int totalBookings = 0;
    final eventBreakdown = <String, int>{};
    final revenueBySource = <String, double>{};
    double totalRevenue = 0;

    // Count engagement events
    for (final data in _engagementBox.values) {
      if (data is Map) {
        final map = data as Map<String, dynamic>;
        if (map['userId'] == userId) {
          final timestamp = DateTime.parse(map['timestamp']);
          if (timestamp.isAfter(start) && timestamp.isBefore(end)) {
            final eventType = map['eventType'] as String;
            eventBreakdown[eventType] = (eventBreakdown[eventType] ?? 0) + 1;

            if (eventType == 'view') totalViews++;
            if (eventType == 'click') totalClicks++;
          }
        }
      }
    }

    // Count conversions
    for (final data in _conversionBox.values) {
      if (data is Map) {
        final map = data as Map<String, dynamic>;
        if (map['userId'] == userId) {
          final timestamp = DateTime.parse(map['timestamp']);
          if (timestamp.isAfter(start) && timestamp.isBefore(end)) {
            final type = map['conversionType'] as String;
            if (type == 'booking') totalBookings++;
          }
        }
      }
    }

    // Sum revenue by source
    for (final data in _revenueBox.values) {
      if (data is Map) {
        final map = data as Map<String, dynamic>;
        if (map['userId'] == userId) {
          final timestamp = DateTime.parse(map['timestamp']);
          if (timestamp.isAfter(start) && timestamp.isBefore(end)) {
            final source = map['source'] as String;
            final amount = (map['amount'] as num).toDouble();
            revenueBySource[source] = (revenueBySource[source] ?? 0) + amount;
            totalRevenue += amount;
          }
        }
      }
    }

    final conversionRate =
        totalViews > 0 ? ((totalBookings / totalViews) * 100).toDouble() : 0.0;

    return AnalyticsSummary(
      userId: userId,
      totalViews: totalViews,
      totalClicks: totalClicks,
      totalBookings: totalBookings,
      totalRevenue: totalRevenue,
      conversionRate: conversionRate,
      periodStart: start,
      periodEnd: end,
      eventTypeBreakdown: eventBreakdown,
      revenueBySource: revenueBySource,
    );
  }

  /// Get platform statistics
  Future<Map<String, dynamic>> getPlatformStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    int totalEngagementEvents = 0;
    int totalConversions = 0;
    double totalPlatformRevenue = 0;
    final uniqueUsers = <String>{};

    // Count engagement
    for (final data in _engagementBox.values) {
      if (data is Map) {
        final map = data as Map<String, dynamic>;
        final timestamp = DateTime.parse(map['timestamp']);
        if (timestamp.isAfter(start) && timestamp.isBefore(end)) {
          totalEngagementEvents++;
          uniqueUsers.add((data)['userId']);
        }
      }
    }

    // Count conversions
    for (final data in _conversionBox.values) {
      if (data is Map) {
        final map = data as Map<String, dynamic>;
        final timestamp = DateTime.parse(map['timestamp']);
        if (timestamp.isAfter(start) && timestamp.isBefore(end)) {
          totalConversions++;
          uniqueUsers.add(map['userId']);
        }
      }
    }

    // Sum revenue
    for (final data in _revenueBox.values) {
      if (data is Map) {
        final map = data as Map<String, dynamic>;
        final timestamp = DateTime.parse(map['timestamp']);
        if (timestamp.isAfter(start) && timestamp.isBefore(end)) {
          totalPlatformRevenue += (map['amount'] as num).toDouble();
        }
      }
    }

    return {
      'totalEngagementEvents': totalEngagementEvents,
      'totalConversions': totalConversions,
      'totalRevenue': totalPlatformRevenue,
      'activeUsers': uniqueUsers.length,
      'averageRevenuePerUser': uniqueUsers.isNotEmpty
          ? totalPlatformRevenue / uniqueUsers.length
          : 0,
      'periodStart': start.toIso8601String(),
      'periodEnd': end.toIso8601String(),
    };
  }

  /// Cleanup old analytics
  Future<void> cleanupOldAnalytics({int daysOld = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    final keysToRemove = <String>[];

    // Cleanup engagement
    for (final entry in _engagementBox.toMap().entries) {
      if (entry.value is Map) {
        final timestamp = DateTime.parse((entry.value as Map)['timestamp']);
        if (timestamp.isBefore(cutoffDate)) {
          keysToRemove.add(entry.key);
        }
      }
    }

    for (final key in keysToRemove) {
      _engagementBox.delete(key);
    }

    // Cleanup conversions
    keysToRemove.clear();
    for (final entry in _conversionBox.toMap().entries) {
      if (entry.value is Map) {
        final timestamp = DateTime.parse((entry.value as Map)['timestamp']);
        if (timestamp.isBefore(cutoffDate)) {
          keysToRemove.add(entry.key);
        }
      }
    }

    for (final key in keysToRemove) {
      _conversionBox.delete(key);
    }

    // Cleanup revenue
    keysToRemove.clear();
    for (final entry in _revenueBox.toMap().entries) {
      if (entry.value is Map) {
        final timestamp = DateTime.parse((entry.value as Map)['timestamp']);
        if (timestamp.isBefore(cutoffDate)) {
          keysToRemove.add(entry.key);
        }
      }
    }

    for (final key in keysToRemove) {
      _revenueBox.delete(key);
    }
  }
}
