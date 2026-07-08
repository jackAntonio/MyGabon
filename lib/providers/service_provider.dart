import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/service_model.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/geolocation_service.dart';
import '../services/supabase_service.dart';

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
  final GeolocationService _geolocationService = GeolocationService();
  Position? _userPosition;
  // Raison du dernier échec de localisation (null = pas d'erreur ou pas encore tenté)
  LocationError? _locationError;

  List<ServiceModel> get services =>
      _filteredServices.isEmpty ? _services : _filteredServices;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasReachedEnd => _hasReachedEnd;
  bool get isSortedByDistance => _userPosition != null;
  /// Raison du dernier échec de tri par proximité (null si succès ou non tenté).
  LocationError? get locationError => _locationError;

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

      final rows = await SupabaseService().getServices(
        page: page,
        pageSize: _pageSize,
      );
      final newServices = rows.map(_serviceFromRow).toList();

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

  /// Trie la liste actuellement affichée par proximité. Voir
  /// MarketplaceProvider.sortByDistance pour la même logique côté produits.
  ///
  /// Retourne null si le tri a réussi, ou un [LocationError] décrivant la
  /// raison de l'échec (GPS désactivé, permission refusée, timeout…).
  Future<LocationError?> sortByDistance() async {
    _locationError = null;

    if (_userPosition == null) {
      final result = await _geolocationService.getCurrentLocation();
      if (result.isSuccess) {
        _userPosition = result.position;
      } else {
        _locationError = result.error;
        return result.error;
      }
    }

    final list = _filteredServices.isEmpty ? _services : _filteredServices;
    list.sort((a, b) {
      final distanceA = distanceKmFor(a);
      final distanceB = distanceKmFor(b);
      if (distanceA == null && distanceB == null) return 0;
      if (distanceA == null) return 1;
      if (distanceB == null) return -1;
      return distanceA.compareTo(distanceB);
    });
    notifyListeners();
    return null; // null = succès
  }

  /// Distance en km entre l'utilisateur et [service], ou null si la
  /// position ou les coordonnées du service sont indisponibles.
  double? distanceKmFor(ServiceModel service) {
    final position = _userPosition;
    if (position == null ||
        service.latitude == null ||
        service.longitude == null) {
      return null;
    }
    return GeolocationService.distanceInKm(
      position.latitude,
      position.longitude,
      service.latitude!,
      service.longitude!,
    );
  }

  /// Refresh services (pull-to-refresh)
  Future<void> refreshServices() async {
    _currentPage = 0;
    _hasReachedEnd = false;
    _loading = true;
    notifyListeners();

    await _fetchServicesPage(0);
  }

  /// Convertit une ligne Supabase (table `services`, avec le profil
  /// prestataire joint sous la clé `provider`) en [ServiceModel].
  ServiceModel _serviceFromRow(Map<String, dynamic> row) {
    final provider = row['provider'] as Map<String, dynamic>?;
    return ServiceModel(
      id: row['id'] as String,
      providerId: row['provider_id'] as String,
      providerName: provider?['full_name'] as String? ?? 'Prestataire',
      providerVerified: provider?['verified'] as bool? ?? false,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      price: (row['price'] as num).toDouble(),
      category: _capitalize(row['category'] as String? ?? 'Autres'),
      location: row['location'] as String? ?? 'Libreville',
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      rating: (row['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (row['reviews_count'] as num?)?.toInt() ?? 0,
    );
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
      'latitude': service.latitude,
      'longitude': service.longitude,
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
                latitude: (item['latitude'] as num?)?.toDouble(),
                longitude: (item['longitude'] as num?)?.toDouble(),
                rating: (item['rating'] as num?)?.toDouble() ?? 4.0,
                reviewsCount: (item['reviews_count'] as num?)?.toInt() ?? 0,
              ))
          .toList();
    }
    return [];
  }
}
