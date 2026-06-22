import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';

/// Marketplace provider with caching, pagination, and offline support
class MarketplaceProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasReachedEnd = false;

  final ConnectivityService? _connectivityService;

  List<ProductModel> get products =>
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

      // Try to load from cache first
      final cachedProducts = CacheService.getProducts('products_page_0');

      if (cachedProducts != null) {
        debugPrint('💾 Produits chargés depuis le cache');
        _products = _parseProductsFromJson(cachedProducts);
        _loading = false;
        notifyListeners();
      }

      // If offline, show cached data, otherwise fetch fresh data
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
      // Check cache first
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
      final newProducts = _generateDummyProducts(page);

      if (newProducts.length < _pageSize) {
        _hasReachedEnd = true;
      }

      if (page == 0) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      // Cache the result
      final jsonData = newProducts.map((p) => _productToJson(p)).toList();
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
      _filteredProducts = _products
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.location.toLowerCase().contains(query.toLowerCase()))
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

  /// Helper: Generate dummy products
  List<ProductModel> _generateDummyProducts(int page) {
    final start = page * _pageSize;
    final dummyNames = [
      'Used Laptop',
      'Smartphone',
      'Tablet',
      'Camera',
      'Headphones',
      'Keyboard',
      'Mouse',
      'Monitor',
      'Speakers',
      'Printer',
      'Router',
      'Hard Drive',
      'SSD',
      'RAM',
      'GPU',
    ];

    final products = <ProductModel>[];
    for (int i = start; i < start + _pageSize && i < 100; i++) {
      products.add(
        ProductModel(
          name: dummyNames[i % dummyNames.length],
          price: 500000 + (i * 50000),
          location: 'Libreville',
        ),
      );
    }

    return products;
  }

  /// Helper: Convert ProductModel to JSON
  Map<String, dynamic> _productToJson(ProductModel product) {
    return {
      'name': product.name,
      'price': product.price,
      'location': product.location,
    };
  }

  /// Helper: Parse products from JSON
  List<ProductModel> _parseProductsFromJson(dynamic json) {
    if (json is List) {
      return json
          .map((item) => ProductModel(
                name: item['name'] as String? ?? 'Product',
                price: (item['price'] as num?)?.toInt() ?? 0,
                location: item['location'] as String? ?? 'Unknown',
              ))
          .toList();
    }
    return [];
  }
}
