import 'package:flutter/material.dart';
import '../models/monetization_models.dart';
import '../services/monetization_service.dart';
import '../services/supabase_service.dart';

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
  
  /// Charge l'abonnement : Supabase (source de vérité serveur) en priorité,
  /// avec repli sur le cache Hive local si l'appel réseau échoue (offline).
  Future<void> loadSubscription(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final serverRow = await SupabaseService().getSubscription();
      if (serverRow != null) {
        _currentSubscription = _subscriptionService.fromServerRow(serverRow);
        await _subscriptionService.cacheFromServer(_currentSubscription!);
      } else {
        _currentSubscription = await _subscriptionService.getUserSubscription(userId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _currentSubscription = await _subscriptionService.getUserSubscription(userId);
      _isLoading = false;
      _error = 'Failed to load subscription';
      notifyListeners();
    }
  }

  /// Souscrit/renouvelle un abonnement Pro ou Entreprise : débite le
  /// MyGabon Wallet côté serveur (RPC purchase_subscription) avant toute
  /// activation. `monthlyPrice` doit venir de ProfessionalPlan, jamais
  /// d'une valeur saisie côté client.
  Future<bool> createSubscription(
    String userId,
    SubscriptionTier tier,
    double monthlyPrice,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final row = await SupabaseService().purchaseSubscription(
        tier: tier.name,
        monthlyPrice: monthlyPrice,
      );
      _currentSubscription = _subscriptionService.fromServerRow(row);
      await _subscriptionService.cacheFromServer(_currentSubscription!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
  
  /// Annule l'abonnement côté serveur (repasse en Free, coupe le
  /// renouvellement, pas de remboursement du mois en cours).
  Future<bool> cancelSubscription(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await SupabaseService().cancelSubscriptionServer();
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
  final RevenuePaymentService _paymentService;
  
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
