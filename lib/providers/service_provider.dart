import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/demo_data.dart';

/// Provides list of services with caching, pagination, and offline support
class ServiceProvider extends ChangeNotifier {
  List<ServiceModel> _services = [];
  List<ServiceModel> _filteredServices = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasReachedEnd = false;

  final ConnectivityService? _connectivityService;

  List<ServiceModel> get services =>
      _filteredServices.isEmpty ? _services : _filteredServices;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasReachedEnd => _hasReachedEnd;

  ServiceProvider(this._connectivityService) {
    _initializeServices();
  }

  /// Initialize services with cache-first strategy
  Future<void> _initializeServices() async {
    try {
      _loading = true;
      notifyListeners();

      final cachedServices = CacheService.getServices('services_page_0');

      if (cachedServices != null) {
        debugPrint('💾 Services chargés depuis le cache');
        _services = _parseServicesFromJson(cachedServices);
        _loading = false;
        notifyListeners();
      }

      if (_connectivityService?.isOnlineMode ?? true) {
        await _fetchServicesPage(0);
      }
    } catch (e) {
      debugPrint('❌ Erreur initialisation services: $e');
      _loading = false;
      notifyListeners();
    }
  }

  /// Lazy load next page of services
  Future<void> loadMore() async {
    if (_loadingMore || _hasReachedEnd) return;

    try {
      _loadingMore = true;
      notifyListeners();

      await _fetchServicesPage(_currentPage + 1);

      _loadingMore = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur chargement plus de services: $e');
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Fetch services with pagination and caching
  Future<void> _fetchServicesPage(int page) async {
    try {
      final cacheKey = 'services_page_$page';
      final cached = CacheService.getServices(cacheKey);

      if (cached != null) {
        final newServices = _parseServicesFromJson(cached);
        if (page == 0) {
          _services = newServices;
        } else {
          _services.addAll(newServices);
        }
        _currentPage = page;
        notifyListeners();
        return;
      }

      if (_connectivityService != null) {
        await _connectivityService!.retryWithBackoff(() async {
          await Future.delayed(const Duration(milliseconds: 500));
          return null;
        });
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // TODO: remplacer par un vrai fetch Supabase (table `services`) une
      // fois le catalogue alimenté en production ; pour l'instant on sert
      // les données de démo gabonaises (demo_data.dart).
      final newServices = _servicesForPage(page);

      if (newServices.length < _pageSize) {
        _hasReachedEnd = true;
      }

      if (page == 0) {
        _services = newServices;
      } else {
        _services.addAll(newServices);
      }

      final jsonData = newServices.map((s) => _serviceToJson(s)).toList();
      await CacheService.cacheServices(cacheKey, jsonData);

      _currentPage = page;
      _loading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur fetch services: $e');
      _loading = false;
      notifyListeners();
    }
  }

  /// Filter services by category
  void filterByCategory(String category) {
    if (category.isEmpty) {
      _filteredServices = [];
    } else {
      _filteredServices =
          _services.where((s) => s.category == category).toList();
    }
    notifyListeners();
  }

  /// Search services by query
  void search(String query) {
    if (query.isEmpty) {
      _filteredServices = [];
    } else {
      final q = query.toLowerCase();
      _filteredServices = _services
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q) ||
              s.location.toLowerCase().contains(q))
          .toList();
    }

    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _filteredServices = [];
    notifyListeners();
  }

  /// Refresh services (pull-to-refresh)
  Future<void> refreshServices() async {
    _currentPage = 0;
    _hasReachedEnd = false;
    _loading = true;
    notifyListeners();

    await _fetchServicesPage(0);
  }

  /// Construire la page de services de démo (villes gabonaises variées).
  List<ServiceModel> _servicesForPage(int page) {
    if (page > 0) return [];

    final rawServices = gabonDemoData['services'] as List<dynamic>;
    final rawUsers = gabonDemoData['users'] as List<dynamic>;
    final locations = ['Libreville', 'Port-Gentil', 'Franceville', 'Lambaréné'];

    return rawServices.asMap().entries.map((entry) {
      final i = entry.key;
      final raw = entry.value as Map<String, dynamic>;
      final provider = rawUsers.cast<Map<String, dynamic>>().firstWhere(
            (u) => u['id'] == raw['provider_id'],
            orElse: () => const {},
          );
      return ServiceModel(
        id: raw['id'] as String,
        providerId: raw['provider_id'] as String,
        providerName: raw['provider_name'] as String,
        providerVerified: provider['verified'] as bool? ?? false,
        title: raw['title'] as String,
        description: raw['description'] as String,
        price: (raw['price'] as num).toDouble(),
        category: _capitalize(raw['category'] as String),
        location: locations[i % locations.length],
        rating: (raw['rating'] as num).toDouble(),
        reviewsCount: (raw['reviews_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// Helper: Convert ServiceModel to JSON
  Map<String, dynamic> _serviceToJson(ServiceModel service) {
    return {
      'id': service.id,
      'provider_id': service.providerId,
      'provider_name': service.providerName,
      'provider_avatar': service.providerAvatar,
      'title': service.title,
      'description': service.description,
      'price': service.price,
      'category': service.category,
      'location': service.location,
      'rating': service.rating,
      'reviews_count': service.reviewsCount,
    };
  }

  /// Helper: Parse services from JSON
  List<ServiceModel> _parseServicesFromJson(dynamic json) {
    if (json is List) {
      return json
          .map((item) => ServiceModel(
                id: item['id'] as String? ?? '',
                providerId: item['provider_id'] as String? ?? '',
                providerName: item['provider_name'] as String? ?? 'Prestataire',
                providerAvatar: item['provider_avatar'] as String?,
                title: item['title'] as String? ?? 'Service',
                description: item['description'] as String? ?? '',
                price: (item['price'] as num?)?.toDouble() ?? 0,
                category: item['category'] as String? ?? 'Autres',
                location: item['location'] as String? ?? 'Libreville',
                rating: (item['rating'] as num?)?.toDouble() ?? 4.0,
                reviewsCount: (item['reviews_count'] as num?)?.toInt() ?? 0,
              ))
          .toList();
    }
    return [];
  }
}
