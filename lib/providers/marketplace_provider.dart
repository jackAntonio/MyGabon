import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/demo_data.dart';

/// Marketplace provider with caching, pagination, and offline support
class MarketplaceProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasReachedEnd = false;

  final ConnectivityService? _connectivityService;

  List<Product> get products =>
      _filteredProducts.isEmpty ? _products : _filteredProducts;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasReachedEnd => _hasReachedEnd;

  MarketplaceProvider(this._connectivityService) {
    _initializeProducts();
  }

  /// Initialize products with cache-first strategy
  Future<void> _initializeProducts() async {
    try {
      _loading = true;
      notifyListeners();

      final cachedProducts = CacheService.getProducts('products_page_0');

      if (cachedProducts != null) {
        debugPrint('💾 Produits chargés depuis le cache');
        _products = _parseProductsFromJson(cachedProducts);
        _loading = false;
        notifyListeners();
      }

      if (_connectivityService?.isOnlineMode ?? true) {
        await _fetchProductsPage(0);
      }
    } catch (e) {
      debugPrint('❌ Erreur initialisation produits: $e');
      _loading = false;
      notifyListeners();
    }
  }

  /// Lazy load next page of products
  Future<void> loadMore() async {
    if (_loadingMore || _hasReachedEnd) return;

    try {
      _loadingMore = true;
      notifyListeners();

      await _fetchProductsPage(_currentPage + 1);

      _loadingMore = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur chargement plus de produits: $e');
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Fetch products with pagination and caching
  Future<void> _fetchProductsPage(int page) async {
    try {
      final cacheKey = 'products_page_$page';
      final cached = CacheService.getProducts(cacheKey);

      if (cached != null) {
        final newProducts = _parseProductsFromJson(cached);
        if (page == 0) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
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

      // TODO: remplacer par un vrai fetch Supabase (table `products`) une fois
      // le catalogue alimenté en production ; pour l'instant on sert les
      // données de démo gabonaises (demo_data.dart) en pages de _pageSize.
      final newProducts = _productsForPage(page);

      if (newProducts.length < _pageSize) {
        _hasReachedEnd = true;
      }

      if (page == 0) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      final jsonData = newProducts.map((p) => p.toJson()).toList();
      await CacheService.cacheProducts(cacheKey, jsonData);

      _currentPage = page;
      _loading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur fetch produits: $e');
      _loading = false;
      notifyListeners();
    }
  }

  /// Search products by query
  void search(String query) {
    if (query.isEmpty) {
      _filteredProducts = [];
    } else {
      final q = query.toLowerCase();
      _filteredProducts = _products
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q) ||
              (p.category?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    notifyListeners();
  }

  /// Filter by price range
  void filterByPrice(double minPrice, double maxPrice) {
    _filteredProducts = _products
        .where((p) => p.price >= minPrice && p.price <= maxPrice)
        .toList();
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _filteredProducts = [];
    notifyListeners();
  }

  /// Refresh products (pull-to-refresh)
  Future<void> refreshProducts() async {
    _currentPage = 0;
    _hasReachedEnd = false;
    _loading = true;
    notifyListeners();

    await _fetchProductsPage(0);
  }

  /// Construire la page de produits de démo (villes et conditions gabonaises
  /// variées pour donner un catalogue plus riche que les 5 entrées de base).
  List<Product> _productsForPage(int page) {
    if (page > 0) return [];

    final rawProducts = gabonDemoData['products'] as List<dynamic>;
    final rawUsers = gabonDemoData['users'] as List<dynamic>;
    final locations = ['Libreville', 'Port-Gentil', 'Franceville', 'Lambaréné'];
    final conditions = ['Neuf', 'Bon état', 'Occasion'];

    return rawProducts.asMap().entries.map((entry) {
      final i = entry.key;
      final raw = entry.value as Map<String, dynamic>;
      final seller = rawUsers.cast<Map<String, dynamic>>().firstWhere(
            (u) => u['id'] == raw['seller_id'],
            orElse: () => const {},
          );
      return Product(
        id: raw['id'] as String,
        title: raw['title'] as String,
        description: raw['description'] as String,
        price: (raw['price'] as num).toDouble(),
        category: raw['category'] as String?,
        imageUrl: null,
        sellerId: raw['seller_id'] as String,
        sellerName: raw['seller_name'] as String,
        sellerRating: (raw['rating'] as num).toDouble(),
        sellerVerified: seller['verified'] as bool? ?? false,
        condition: conditions[i % conditions.length],
        location: locations[i % locations.length],
        createdAt: DateTime.now().subtract(Duration(days: i)),
        quantity: 1,
        published: true,
      );
    }).toList();
  }

  /// Helper: Parse products from JSON (cache)
  List<Product> _parseProductsFromJson(dynamic json) {
    if (json is List) {
      return json.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
