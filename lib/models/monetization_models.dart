/// Professional subscription plans
enum SubscriptionTier { free, professional, enterprise }

/// Subscription plan details
class ProfessionalPlan {
  final SubscriptionTier tier;
  final String name;
  final String description;
  final double monthlyPrice;
  final int billingDays;
  final List<String> benefits;
  final int maxListings;
  final int maxFeaturedListings;
  final bool analyticsAccess;
  
  ProfessionalPlan({
    required this.tier,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.billingDays,
    required this.benefits,
    required this.maxListings,
    required this.maxFeaturedListings,
    required this.analyticsAccess,
  });
  
  static ProfessionalPlan professional() => ProfessionalPlan(
    tier: SubscriptionTier.professional,
    name: 'Professionnel',
    description: 'Package essentiels pour services',
    monthlyPrice: 9999,  // CFA
    billingDays: 30,
    benefits: [
      'Badge vérifié professionnel',
      'Jusqu\'à 5 annonces en vedette/mois',
      'Priorité dans les recherches',
      'Tableau de bord analytique basique',
      'Support prioritaire',
      'Statistiques clients',
    ],
    maxListings: 50,
    maxFeaturedListings: 5,
    analyticsAccess: true,
  );
  
  static ProfessionalPlan enterprise() => ProfessionalPlan(
    tier: SubscriptionTier.enterprise,
    name: 'Entreprise',
    description: 'Pour les petites entreprises',
    monthlyPrice: 24999,  // CFA
    billingDays: 30,
    benefits: [
      'Badge Entreprise Certifiée',
      'Annonces en vedette illimitées',
      'Priorité absolue dans les recherches',
      'Tableau de bord analytique avancé',
      'Support dédié 24/7',
      'API d\'intégration',
      'Publicités sponsorisées',
      'Multi-utilisateurs',
      'Rapports personnalisés',
    ],
    maxListings: 500,
    maxFeaturedListings: -1,  // unlimited
    analyticsAccess: true,
  );
  
  static List<ProfessionalPlan> allPlans() => [
    professional(),
    enterprise(),
  ];
}

/// User subscription status
class UserSubscription {
  final String userId;
  final SubscriptionTier currentTier;
  final DateTime startDate;
  final DateTime renewalDate;
  final bool isActive;
  final bool autoRenew;
  final int featuredListingsUsed;
  final DateTime? cancelledAt;
  
  UserSubscription({
    required this.userId,
    required this.currentTier,
    required this.startDate,
    required this.renewalDate,
    required this.isActive,
    this.autoRenew = true,
    this.featuredListingsUsed = 0,
    this.cancelledAt,
  });
  
  bool get isProfessional => currentTier == SubscriptionTier.professional;
  bool get isEnterprise => currentTier == SubscriptionTier.enterprise;
  
  int get daysUntilRenewal => renewalDate.difference(DateTime.now()).inDays;
  
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'currentTier': currentTier.toString(),
    'startDate': startDate.toIso8601String(),
    'renewalDate': renewalDate.toIso8601String(),
    'isActive': isActive,
    'autoRenew': autoRenew,
    'featuredListingsUsed': featuredListingsUsed,
    'cancelledAt': cancelledAt?.toIso8601String(),
  };
}

/// Featured listing boost
class FeaturedListing {
  final String id;
  final String listingId;
  final String userId;
  final DateTime startDate;
  final DateTime expiryDate;
  final double boostPrice;
  final int positionBoost;  // 1-10, higher = more prominent
  final bool isFeatured;  // True if currently active
  final String? paymentId;
  
  FeaturedListing({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.startDate,
    required this.expiryDate,
    required this.boostPrice,
    this.positionBoost = 5,
    required this.isFeatured,
    this.paymentId,
  });
  
  bool get isActive => DateTime.now().isBefore(expiryDate);
  int get daysRemaining => expiryDate.difference(DateTime.now()).inDays;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'listingId': listingId,
    'userId': userId,
    'startDate': startDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'boostPrice': boostPrice,
    'positionBoost': positionBoost,
    'isFeatured': isFeatured,
    'paymentId': paymentId,
  };
}

/// In-app advertisement entity
class Advertisement {
  final String id;
  final String businessId;
  final String title;
  final String description;
  final String imageUrl;
  final String? actionUrl;
  final DateTime startDate;
  final DateTime expiryDate;
  final double cost;
  final int impressions;
  final int clicks;
  final String adType;  // 'banner', 'sponsored_service', 'featured_store'
  
  Advertisement({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.actionUrl,
    required this.startDate,
    required this.expiryDate,
    required this.cost,
    this.impressions = 0,
    this.clicks = 0,
    this.adType = 'banner',
  });
  
  bool get isActive => DateTime.now().isBefore(expiryDate) && DateTime.now().isAfter(startDate);
  double get ctr => impressions > 0 ? (clicks / impressions) * 100 : 0;  // Click-through rate
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'businessId': businessId,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'actionUrl': actionUrl,
    'startDate': startDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'cost': cost,
    'impressions': impressions,
    'clicks': clicks,
    'adType': adType,
  };
}

/// Transaction with commission tracking
class MonetizedTransaction {
  final String id;
  final String buyerId;
  final String sellerId;
  final double amount;
  final double platformCommissionPercentage;
  final DateTime createdAt;
  final bool platformFeeApplied;
  final String serviceId;
  final String? subscriptionId;  // Link to professional account
  
  double get platformCommission => amount * (platformCommissionPercentage / 100);
  double get sellerAmount => amount - platformCommission;
  
  MonetizedTransaction({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    this.platformCommissionPercentage = 10.0,
    DateTime? createdAt,
    this.platformFeeApplied = true,
    required this.serviceId,
    this.subscriptionId,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'buyerId': buyerId,
    'sellerId': sellerId,
    'amount': amount,
    'platformCommissionPercentage': platformCommissionPercentage,
    'platformCommission': platformCommission,
    'sellerAmount': sellerAmount,
    'createdAt': createdAt.toIso8601String(),
    'platformFeeApplied': platformFeeApplied,
    'serviceId': serviceId,
    'subscriptionId': subscriptionId,
  };
}

/// Service convenience fee structure
class ConvenienceFee {
  final String id;
  final String serviceId;
  final String description;
  final double feeAmount;
  final double feePercentage;  // As percentage of service price
  final bool optional;
  final String purpose;  // 'insurance', 'delivery', 'support', 'priority'
  
  ConvenienceFee({
    required this.id,
    required this.serviceId,
    required this.description,
    required this.feeAmount,
    this.feePercentage = 0,
    this.optional = true,
    this.purpose = 'support',
  });
  
  double calculateFee(double baseAmount) {
    if (feePercentage > 0) {
      return baseAmount * (feePercentage / 100);
    }
    return feeAmount;
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'serviceId': serviceId,
    'description': description,
    'feeAmount': feeAmount,
    'feePercentage': feePercentage,
    'optional': optional,
    'purpose': purpose,
  };
}

/// Revenue and earnings summary
class RevenueSummary {
  final String userId;
  final double totalEarnings;
  final double platformCommissionsPaid;
  final double subscriptionsFeesPaid;
  final double featuredListingsCost;
  final double averageTransactionValue;
  final int totalTransactions;
  final DateTime periodStart;
  final DateTime periodEnd;
  
  RevenueSummary({
    required this.userId,
    required this.totalEarnings,
    required this.platformCommissionsPaid,
    required this.subscriptionsFeesPaid,
    required this.featuredListingsCost,
    required this.averageTransactionValue,
    required this.totalTransactions,
    required this.periodStart,
    required this.periodEnd,
  });
  
  double get netEarnings => totalEarnings - platformCommissionsPaid - subscriptionsFeesPaid - featuredListingsCost;
  
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'totalEarnings': totalEarnings,
    'platformCommissionsPaid': platformCommissionsPaid,
    'subscriptionsFeesPaid': subscriptionsFeesPaid,
    'featuredListingsCost': featuredListingsCost,
    'averageTransactionValue': averageTransactionValue,
    'totalTransactions': totalTransactions,
    'netEarnings': netEarnings,
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
  };
}
