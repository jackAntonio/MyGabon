import 'package:flutter/material.dart';
import '../models/monetization_models.dart';
import '../services/monetization_service.dart';

/// Provider for managing subscriptions
class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService;
  
  UserSubscription? _currentSubscription;
  bool _isLoading = false;
  String? _error;
  
  SubscriptionProvider(this._subscriptionService);
  
  // Getters
  UserSubscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get isProfessional => _currentSubscription?.currentTier == SubscriptionTier.professional;
  bool get isEnterprise => _currentSubscription?.currentTier == SubscriptionTier.enterprise;
  bool get hasActiveSubscription => _currentSubscription?.isActive ?? false;
  
  /// Load user subscription
  Future<void> loadSubscription(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _currentSubscription = await _subscriptionService.getUserSubscription(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load subscription';
      notifyListeners();
    }
  }
  
  /// Create subscription
  Future<bool> createSubscription(String userId, SubscriptionTier tier) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _subscriptionService.createSubscription(userId, tier);
      await loadSubscription(userId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to create subscription';
      notifyListeners();
      return false;
    }
  }
  
  /// Upgrade subscription
  Future<bool> upgradeSubscription(String userId, SubscriptionTier newTier) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final success = await _subscriptionService.upgradeSubscription(userId, newTier);
      if (success) {
        await loadSubscription(userId);
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to upgrade subscription';
      notifyListeners();
      return false;
    }
  }
  
  /// Cancel subscription
  Future<bool> cancelSubscription(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _subscriptionService.cancelSubscription(userId);
      await loadSubscription(userId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to cancel subscription';
      notifyListeners();
      return false;
    }
  }
  
  /// Check featured listing availability
  Future<bool> canUseFeaturedListing(String userId) async {
    try {
      final sub = await _subscriptionService.getUserSubscription(userId);
      if (sub == null || !sub.isActive) return false;
      
      final plan = sub.currentTier == SubscriptionTier.professional
          ? ProfessionalPlan.professional()
          : ProfessionalPlan.enterprise();
      
      if (plan.maxFeaturedListings == -1) return true;  // Unlimited
      return sub.featuredListingsUsed < plan.maxFeaturedListings;
    } catch (e) {
      return false;
    }
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Provider for managing featured listings
class FeaturedListingProvider extends ChangeNotifier {
  final FeaturedListingService _featuredService;
  
  List<FeaturedListing> _userFeaturedListings = [];
  bool _isLoading = false;
  String? _error;
  
  FeaturedListingProvider(this._featuredService);
  
  // Getters
  List<FeaturedListing> get userFeaturedListings => _userFeaturedListings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Load user featured listings
  Future<void> loadUserFeaturedListings(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _userFeaturedListings = await _featuredService.getUserFeaturedListings(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load featured listings';
      notifyListeners();
    }
  }
  
  /// Boost a listing
  Future<bool> boostListing({
    required String listingId,
    required String userId,
    required int durationDays,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _featuredService.boostListing(
        listingId: listingId,
        userId: userId,
        durationDays: durationDays,
      );
      
      await loadUserFeaturedListings(userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to boost listing';
      notifyListeners();
      return false;
    }
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Provider for managing payments and revenue
class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService;
  
  RevenueSummary? _revenueSummary;
  List<MonetizedTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  
  PaymentProvider(this._paymentService);
  
  // Getters
  RevenueSummary? get revenueSummary => _revenueSummary;
  List<MonetizedTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Load user revenue summary
  Future<void> loadRevenueSummary(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _revenueSummary = await _paymentService.getRevenueSummary(userId);
      _transactions = await _paymentService.getUserTransactions(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load revenue data';
      notifyListeners();
    }
  }
  
  /// Record transaction
  Future<bool> recordTransaction({
    required String buyerId,
    required String sellerId,
    required double amount,
    required String serviceId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _paymentService.recordTransaction(
        buyerId: buyerId,
        sellerId: sellerId,
        amount: amount,
        serviceId: serviceId,
      );
      
      await loadRevenueSummary(sellerId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to record transaction';
      notifyListeners();
      return false;
    }
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
