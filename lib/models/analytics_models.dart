/// Engagement metrics
class EngagementMetric {
  final String id;
  final String userId;
  final String eventType;  // 'view', 'click', 'share', 'favorite', 'contact'
  final String? targetId;  // listing/service ID
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  
  EngagementMetric({
    required this.id,
    required this.userId,
    required this.eventType,
    this.targetId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  })  : timestamp = timestamp ?? DateTime.now(),
        metadata = metadata ?? {};
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'eventType': eventType,
    'targetId': targetId,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };
}

/// Conversion metrics
class ConversionMetric {
  final String id;
  final String userId;
  final String conversionType;  // 'booking', 'purchase', 'subscription', 'featured_listing'
  final double revenue;
  final String? relatedUserId;  // buyer/seller
  final DateTime timestamp;
  final String? promoCodeUsed;
  
  ConversionMetric({
    required this.id,
    required this.userId,
    required this.conversionType,
    required this.revenue,
    this.relatedUserId,
    DateTime? timestamp,
    this.promoCodeUsed,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'conversionType': conversionType,
    'revenue': revenue,
    'relatedUserId': relatedUserId,
    'timestamp': timestamp.toIso8601String(),
    'promoCodeUsed': promoCodeUsed,
  };
}

/// Revenue metrics
class RevenueMetric {
  final String id;
  final String source;  // 'subscription', 'featured_listing', 'commission', 'ads'
  final double amount;
  final String? userId;  // the user who generated this revenue
  final DateTime timestamp;
  final String currency;
  
  RevenueMetric({
    required this.id,
    required this.source,
    required this.amount,
    this.userId,
    DateTime? timestamp,
    this.currency = 'CFA',
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'amount': amount,
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
    'currency': currency,
  };
}

/// Analytics summary
class AnalyticsSummary {
  final String userId;
  final int totalViews;
  final int totalClicks;
  final int totalBookings;
  final double totalRevenue;
  final double conversionRate;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, int> eventTypeBreakdown;
  final Map<String, double> revenueBySource;
  
  AnalyticsSummary({
    required this.userId,
    required this.totalViews,
    required this.totalClicks,
    required this.totalBookings,
    required this.totalRevenue,
    required this.conversionRate,
    required this.periodStart,
    required this.periodEnd,
    required this.eventTypeBreakdown,
    required this.revenueBySource,
  });
  
  int get engagementRate => totalViews > 0 ? ((totalClicks / totalViews) * 100).toInt() : 0;
  int get daysInPeriod => periodEnd.difference(periodStart).inDays;
  
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'totalViews': totalViews,
    'totalClicks': totalClicks,
    'totalBookings': totalBookings,
    'totalRevenue': totalRevenue,
    'conversionRate': conversionRate,
    'engagementRate': engagementRate,
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'eventTypeBreakdown': eventTypeBreakdown,
    'revenueBySource': revenueBySource,
  };
}

/// Promotional offer
class PromoCode {
  final String code;
  final String description;
  final double discountPercentage;
  final int maxUses;
  final int usesRemaining;
  final DateTime validFrom;
  final DateTime validUntil;
  final String applicableTo;  // 'subscription', 'featured_listing', 'all'
  final bool isActive;
  
  PromoCode({
    required this.code,
    required this.description,
    required this.discountPercentage,
    required this.maxUses,
    required this.usesRemaining,
    required this.validFrom,
    required this.validUntil,
    this.applicableTo = 'all',
    this.isActive = true,
  });
  
  bool get isValid {
    final now = DateTime.now();
    return isActive && 
        now.isAfter(validFrom) && 
        now.isBefore(validUntil) && 
        usesRemaining > 0;
  }
  
  Map<String, dynamic> toJson() => {
    'code': code,
    'description': description,
    'discountPercentage': discountPercentage,
    'maxUses': maxUses,
    'usesRemaining': usesRemaining,
    'validFrom': validFrom.toIso8601String(),
    'validUntil': validUntil.toIso8601String(),
    'applicableTo': applicableTo,
    'isActive': isActive,
  };
}

/// Referral reward program
class ReferralReward {
  final String id;
  final String referrerId;
  final String referredUserId;
  final String rewardType;  // 'credit', 'discount', 'free_featured'
  final double rewardValue;
  final DateTime createdAt;
  final bool rewardClaimed;
  
  ReferralReward({
    required this.id,
    required this.referrerId,
    required this.referredUserId,
    required this.rewardType,
    required this.rewardValue,
    DateTime? createdAt,
    this.rewardClaimed = false,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'referrerId': referrerId,
    'referredUserId': referredUserId,
    'rewardType': rewardType,
    'rewardValue': rewardValue,
    'createdAt': createdAt.toIso8601String(),
    'rewardClaimed': rewardClaimed,
  };
}
