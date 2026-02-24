import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/monetization_models.dart';

/// Service for managing professional subscriptions
class SubscriptionService {
  static const String _subscriptionBoxName = 'subscriptions';
  
  late Box<dynamic> _subscriptionBox;
  
  static final SubscriptionService _instance = SubscriptionService._internal();
  
  factory SubscriptionService() {
    return _instance;
  }
  
  SubscriptionService._internal();
  
  /// Initialize Hive box
  Future<void> init() async {
    _subscriptionBox = await Hive.openBox(_subscriptionBoxName);
  }
  
  /// Get user subscription
  Future<UserSubscription?> getUserSubscription(String userId) async {
    final data = _subscriptionBox.get(userId);
    if (data == null) return null;
    
    final map = data as Map<String, dynamic>;
    return UserSubscription(
      userId: userId,
      currentTier: _parseTier(map['currentTier']),
      startDate: DateTime.parse(map['startDate']),
      renewalDate: DateTime.parse(map['renewalDate']),
      isActive: map['isActive'],
      autoRenew: map['autoRenew'] ?? true,
      featuredListingsUsed: map['featuredListingsUsed'] ?? 0,
      cancelledAt: map['cancelledAt'] != null ? DateTime.parse(map['cancelledAt']) : null,
    );
  }
  
  /// Create subscription
  Future<void> createSubscription(String userId, SubscriptionTier tier) async {
    final now = DateTime.now();
    final renewal = now.add(Duration(days: 30));
    
    final subscription = UserSubscription(
      userId: userId,
      currentTier: tier,
      startDate: now,
      renewalDate: renewal,
      isActive: true,
      autoRenew: true,
      featuredListingsUsed: 0,
    );
    
    _subscriptionBox.put(userId, subscription.toJson());
  }
  
  /// Upgrade subscription
  Future<bool> upgradeSubscription(String userId, SubscriptionTier newTier) async {
    final existing = await getUserSubscription(userId);
    if (existing == null) return false;
    
    final upgraded = UserSubscription(
      userId: userId,
      currentTier: newTier,
      startDate: existing.startDate,
      renewalDate: DateTime.now().add(Duration(days: 30)),
      isActive: true,
      autoRenew: true,
      featuredListingsUsed: 0,
    );
    
    _subscriptionBox.put(userId, upgraded.toJson());
    return true;
  }
  
  /// Cancel subscription
  Future<void> cancelSubscription(String userId) async {
    final existing = await getUserSubscription(userId);
    if (existing == null) return;
    
    final cancelled = UserSubscription(
      userId: userId,
      currentTier: SubscriptionTier.free,
      startDate: existing.startDate,
      renewalDate: existing.renewalDate,
      isActive: false,
      autoRenew: false,
      featuredListingsUsed: existing.featuredListingsUsed,
      cancelledAt: DateTime.now(),
    );
    
    _subscriptionBox.put(userId, cancelled.toJson());
  }
  
  /// Use featured listing slot
  Future<bool> useFeaturedListing(String userId) async {
    final sub = await getUserSubscription(userId);
    if (sub == null || !sub.isActive) return false;
    
    final plan = sub.currentTier == SubscriptionTier.professional
        ? ProfessionalPlan.professional()
        : ProfessionalPlan.enterprise();
    
    // Check if limit exceeded
    if (plan.maxFeaturedListings > 0 && 
        sub.featuredListingsUsed >= plan.maxFeaturedListings) {
      return false;
    }
    
    // Increment usage
    final updated = UserSubscription(
      userId: userId,
      currentTier: sub.currentTier,
      startDate: sub.startDate,
      renewalDate: sub.renewalDate,
      isActive: sub.isActive,
      autoRenew: sub.autoRenew,
      featuredListingsUsed: sub.featuredListingsUsed + 1,
    );
    
    _subscriptionBox.put(userId, updated.toJson());
    return true;
  }
  
  /// Reset featured listings monthly
  Future<void> resetMonthlyLimits(String userId) async {
    final sub = await getUserSubscription(userId);
    if (sub == null) return;
    
    final updated = UserSubscription(
      userId: userId,
      currentTier: sub.currentTier,
      startDate: sub.startDate,
      renewalDate: DateTime.now().add(Duration(days: 30)),
      isActive: sub.isActive,
      autoRenew: sub.autoRenew,
      featuredListingsUsed: 0,
    );
    
    _subscriptionBox.put(userId, updated.toJson());
  }
  
  /// Get all subscriptions
  Future<List<UserSubscription>> getAllSubscriptions() async {
    final subscriptions = <UserSubscription>[];
    
    for (final data in _subscriptionBox.values) {
      if (data is Map) {
        final map = data as Map<String, dynamic>;
        subscriptions.add(UserSubscription(
          userId: map['userId'],
          currentTier: _parseTier(map['currentTier']),
          startDate: DateTime.parse(map['startDate']),
          renewalDate: DateTime.parse(map['renewalDate']),
          isActive: map['isActive'],
          autoRenew: map['autoRenew'] ?? true,
          featuredListingsUsed: map['featuredListingsUsed'] ?? 0,
        ));
      }
    }
    
    return subscriptions;
  }
  
  SubscriptionTier _parseTier(String tier) {
    if (tier.contains('professional')) return SubscriptionTier.professional;
    if (tier.contains('enterprise')) return SubscriptionTier.enterprise;
    return SubscriptionTier.free;
  }
}

/// Service for managing featured listings
class FeaturedListingService {
  static const String _featuredBoxName = 'featured_listings';
  static const double _boostPrice7Days = 4999;    // CFA
  static const double _boostPrice30Days = 14999;
  
  late Box<dynamic> _featuredBox;
  
  static final FeaturedListingService _instance = FeaturedListingService._internal();
  
  factory FeaturedListingService() {
    return _instance;
  }
  
  FeaturedListingService._internal();
  
  /// Initialize Hive box
  Future<void> init() async {
    _featuredBox = await Hive.openBox(_featuredBoxName);
  }
  
  /// Boost a listing
  Future<FeaturedListing> boostListing({
    required String listingId,
    required String userId,
    required int durationDays,
  }) async {
    final boostPrice = durationDays == 7 ? _boostPrice7Days : _boostPrice30Days;
    
    final featured = FeaturedListing(
      id: const Uuid().v4(),
      listingId: listingId,
      userId: userId,
      startDate: DateTime.now(),
      expiryDate: DateTime.now().add(Duration(days: durationDays)),
      boostPrice: boostPrice,
      positionBoost: 8,  // High visibility
      isFeatured: true,
    );
    
    _featuredBox.put(featured.id, featured.toJson());
    return featured;
  }
  
  /// Get active featured listings
  Future<List<FeaturedListing>> getActiveFeaturedListings() async {
    final featured = <FeaturedListing>[];
    
    for (final data in _featuredBox.values) {
      if (data is Map) {
        final map = data as Map<String, dynamic>;
        final listing = FeaturedListing(
          id: map['id'],
          listingId: map['listingId'],
          userId: map['userId'],
          startDate: DateTime.parse(map['startDate']),
          expiryDate: DateTime.parse(map['expiryDate']),
          boostPrice: map['boostPrice'],
          positionBoost: map['positionBoost'] ?? 5,
          isFeatured: map['isFeatured'],
        );
        
        if (listing.isActive) {
          featured.add(listing);
        }
      }
    }
    
    return featured;
  }
  
  /// Get user featured listings
  Future<List<FeaturedListing>> getUserFeaturedListings(String userId) async {
    final userFeatured = <FeaturedListing>[];
    
    for (final data in _featuredBox.values) {
      if (data is Map) {
        final map = data as Map<String, dynamic>;
        if (map['userId'] == userId) {
          userFeatured.add(FeaturedListing(
            id: map['id'],
            listingId: map['listingId'],
            userId: map['userId'],
            startDate: DateTime.parse(map['startDate']),
            expiryDate: DateTime.parse(map['expiryDate']),
            boostPrice: map['boostPrice'],
            positionBoost: map['positionBoost'] ?? 5,
            isFeatured: map['isFeatured'],
          ));
        }
      }
    }
    
    return userFeatured;
  }
  
  /// Remove expired featured listings
  Future<void> cleanupExpiredBoosters() async {
    final keysToRemove = <String>[];
    
    for (final entry in _featuredBox.toMap().entries) {
      if (entry.value is Map) {
        final expiry = DateTime.parse((entry.value as Map)['expiryDate']);
        if (DateTime.now().isAfter(expiry)) {
          keysToRemove.add(entry.key);
        }
      }
    }
    
    for (final key in keysToRemove) {
      _featuredBox.delete(key);
    }
  }
}

/// Service for managing payments and transactions
class PaymentService {
  static const String _transactionBoxName = 'transactions';
  
  late Box<dynamic> _transactionBox;
  
  static final PaymentService _instance = PaymentService._internal();
  
  factory PaymentService() {
    return _instance;
  }
  
  PaymentService._internal();
  
  /// Initialize Hive box
  Future<void> init() async {
    _transactionBox = await Hive.openBox(_transactionBoxName);
  }
  
  /// Record transaction
  Future<String> recordTransaction({
    required String buyerId,
    required String sellerId,
    required double amount,
    required String serviceId,
    double platformCommissionPercentage = 10.0,
  }) async {
    final transaction = MonetizedTransaction(
      id: const Uuid().v4(),
      buyerId: buyerId,
      sellerId: sellerId,
      amount: amount,
      platformCommissionPercentage: platformCommissionPercentage,
      serviceId: serviceId,
    );
    
    _transactionBox.put(transaction.id, transaction.toJson());
    return transaction.id;
  }
  
  /// Get user transactions
  Future<List<MonetizedTransaction>> getUserTransactions(String userId) async {
    final transactions = <MonetizedTransaction>[];
    
    for (final data in _transactionBox.values) {
      if (data is Map) {
        final map = data as Map<String, dynamic>;
        if (map['sellerId'] == userId || map['buyerId'] == userId) {
          transactions.add(MonetizedTransaction(
            id: map['id'],
            buyerId: map['buyerId'],
            sellerId: map['sellerId'],
            amount: (map['amount'] as num).toDouble(),
            platformCommissionPercentage: (map['platformCommissionPercentage'] as num).toDouble(),
            serviceId: map['serviceId'],
          ));
        }
      }
    }
    
    return transactions;
  }
  
  /// Get revenue summary
  Future<RevenueSummary> getRevenueSummary(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
    final end = endDate ?? DateTime.now();
    
    final transactions = await getUserTransactions(userId);
    
    double totalEarnings = 0;
    double platformCommissions = 0;
    int totalCount = 0;
    
    for (final tx in transactions) {
      if (tx.sellerId == userId && 
          tx.createdAt.isAfter(start) && 
          tx.createdAt.isBefore(end)) {
        totalEarnings += tx.amount;
        platformCommissions += tx.platformCommission;
        totalCount++;
      }
    }
    
    return RevenueSummary(
      userId: userId,
      totalEarnings: totalEarnings,
      platformCommissionsPaid: platformCommissions,
      subscriptionsFeesPaid: 0,  // Would calculate from subscription records
      featuredListingsCost: 0,   // Would calculate from featured listing records
      averageTransactionValue: totalCount > 0 ? totalEarnings / totalCount : 0,
      totalTransactions: totalCount,
      periodStart: start,
      periodEnd: end,
    );
  }
}
