import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';

/// Provides list of services with caching, pagination, and offline support
class ServiceProvider extends ChangeNotifier {
  List<ServiceModel> _services = [];
  List<ServiceModel> _filteredServices = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 0;
  int _pageSize = 20;
  bool _hasReachedEnd = false;
  
  final ConnectivityService? _connectivityService;
  
  List<ServiceModel> get services => _filteredServices.isEmpty ? _services : _filteredServices;
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
      
      // Try to load from cache first
      final cachedServices = CacheService.getServices('services_page_0');
      
      if (cachedServices != null) {
        debugPrint('💾 Services chargés depuis le cache');
        _services = _parseServicesFromJson(cachedServices);
        _loading = false;
        notifyListeners();
      }
      
      // If offline, show cached data, otherwise fetch fresh data
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
      // Check cache first
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
      
      // Simulate network request with retry logic
      if (_connectivityService != null) {
        await _connectivityService!.retryWithBackoff(() async {
          await Future.delayed(const Duration(milliseconds: 500));
          return null;
        });
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Generate dummy data (replace with API call)
      final newServices = _generateDummyServices(page);
      
      if (newServices.length < _pageSize) {
        _hasReachedEnd = true;
      }
      
      if (page == 0) {
        _services = newServices;
      } else {
        _services.addAll(newServices);
      }
      
      // Cache the result
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
      _filteredServices = _services
          .where((s) => s.description.toLowerCase().contains(category.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }
  
  /// Search services by query
  void search(String query) {
    if (query.isEmpty) {
      _filteredServices = [];
    } else {
      _filteredServices = _services
          .where((s) =>
            s.title.toLowerCase().contains(query.toLowerCase()) ||
            s.description.toLowerCase().contains(query.toLowerCase()) ||
            s.location.toLowerCase().contains(query.toLowerCase()))
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
  
  /// Helper: Generate dummy services
  List<ServiceModel> _generateDummyServices(int page) {
    final start = page * _pageSize;
    final dummyTitles = [
      'Plumbing Repair', 'Computer Repair', 'Electrical Work', 'Cleaning Service',
      'Gardening', 'Painting', 'Car Repair', 'Mobile Repair', 'Carpentry', 'Tutoring',
      'Photography', 'Writing Services', 'Video Editing', 'Graphic Design', 'Coaching',
    ];
    
    final services = <ServiceModel>[];
    for (int i = start; i < start + _pageSize && i < 100; i++) {
      services.add(
        ServiceModel(
          title: dummyTitles[i % dummyTitles.length],
          description: 'Professional service in category ${(i ~/ dummyTitles.length) + 1}',
          location: 'Libreville',
          rating: 4.0 + (i % 10) / 10,
        ),
      );
    }
    
    return services;
  }
  
  /// Helper: Convert ServiceModel to JSON
  Map<String, dynamic> _serviceToJson(ServiceModel service) {
    return {
      'title': service.title,
      'description': service.description,
      'location': service.location,
      'rating': service.rating,
    };
  }
  
  /// Helper: Parse services from JSON
  List<ServiceModel> _parseServicesFromJson(dynamic json) {
    if (json is List) {
      return json.map((item) => ServiceModel(
        title: item['title'] as String? ?? 'Service',
        description: item['description'] as String? ?? '',
        location: item['location'] as String? ?? 'Unknown',
        rating: (item['rating'] as num?)?.toDouble() ?? 4.0,
      )).toList();
    }
    return [];
  }
}
