import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/product.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/geolocation_service.dart';
import '../services/supabase_service.dart';

/// Marketplace provider with caching, pagination, and offline support
class MarketplaceProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasReachedEnd = false;

  final ConnectivityService? _connectivityService;
  final GeolocationService _geolocationService = GeolocationService();
  Position? _userPosition;

  List<Product> get products =>
      _filteredProducts.isEmpty ? _products : _filteredProducts;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasReachedEnd => _hasReachedEnd;
  bool get isSortedByDistance => _userPosition != null;
  String? get selectedCategory => _selectedCategory;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  bool get hasActiveFilters =>
      _selectedCategory != null || _minPrice != null || _maxPrice != null;

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

      final rows = await SupabaseService().getAllProducts(
        page: page,
        pageSize: _pageSize,
      );
      final newProducts = rows.map(_productFromRow).toList();

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

  /// Search products by query (texte libre : titre, lieu, catégorie).
  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Filtre par catégorie (null = toutes les catégories).
  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  /// Filtre par fourchette de prix (null/null = pas de limite).
  void filterByPrice(double? minPrice, double? maxPrice) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _applyFilters();
  }

  /// Réinitialise recherche, catégorie et prix.
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _minPrice = null;
    _maxPrice = null;
    _filteredProducts = [];
    notifyListeners();
  }

  /// Recalcule `_filteredProducts` à partir de `_products` en combinant
  /// recherche texte, catégorie et fourchette de prix (les trois filtres
  /// précédents s'écrasaient l'un l'autre avant cette réécriture).
  void _applyFilters() {
    final q = _searchQuery.toLowerCase();
    final hasQuery = q.isNotEmpty;

    if (!hasQuery && _selectedCategory == null && _minPrice == null && _maxPrice == null) {
      _filteredProducts = [];
      notifyListeners();
      return;
    }

    _filteredProducts = _products.where((p) {
      if (hasQuery &&
          !p.title.toLowerCase().contains(q) &&
          !p.location.toLowerCase().contains(q) &&
          !(p.category?.toLowerCase().contains(q) ?? false)) {
        return false;
      }
      if (_selectedCategory != null && p.category != _selectedCategory) {
        return false;
      }
      if (_minPrice != null && p.price < _minPrice!) return false;
      if (_maxPrice != null && p.price > _maxPrice!) return false;
      return true;
    }).toList();
    notifyListeners();
  }

  /// Trie la liste actuellement affichée par proximité. Demande la
  /// position si elle n'a pas déjà été récupérée. Renvoie false si la
  /// position est indisponible (permission refusée, GPS désactivé) —
  /// l'appelant doit alors informer l'utilisateur, la liste reste inchangée.
  Future<bool> sortByDistance() async {
    _userPosition ??= await _geolocationService.getCurrentLocation();
    if (_userPosition == null) return false;

    final list = _filteredProducts.isEmpty ? _products : _filteredProducts;
    list.sort((a, b) {
      final distanceA = distanceKmFor(a);
      final distanceB = distanceKmFor(b);
      if (distanceA == null && distanceB == null) return 0;
      if (distanceA == null) return 1;
      if (distanceB == null) return -1;
      return distanceA.compareTo(distanceB);
    });
    notifyListeners();
    return true;
  }

  /// Distance en km entre l'utilisateur et [product], ou null si la
  /// position n'a pas encore été récupérée ou que le produit n'a pas de
  /// coordonnées (annonce publiée avant l'ajout de cette fonctionnalité).
  double? distanceKmFor(Product product) {
    final position = _userPosition;
    if (position == null ||
        product.latitude == null ||
        product.longitude == null) {
      return null;
    }
    return GeolocationService.distanceInKm(
      position.latitude,
      position.longitude,
      product.latitude!,
      product.longitude!,
    );
  }

  /// Refresh products (pull-to-refresh)
  Future<void> refreshProducts() async {
    _currentPage = 0;
    _hasReachedEnd = false;
    _loading = true;
    notifyListeners();

    await _fetchProductsPage(0);
  }

  /// Convertit une ligne Supabase (table `products`, avec le profil vendeur
  /// joint sous la clé `seller`) en [Product].
  Product _productFromRow(Map<String, dynamic> row) {
    final seller = row['seller'] as Map<String, dynamic>?;
    return Product(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      price: (row['price'] as num).toDouble(),
      category: row['category'] as String?,
      imageUrl: row['image_url'] as String?,
      sellerId: row['seller_id'] as String,
      sellerName: seller?['full_name'] as String? ?? 'Vendeur',
      sellerRating: (seller?['rating'] as num?)?.toDouble() ?? 0,
      sellerVerified: seller?['verified'] as bool? ?? false,
      condition: row['condition'] as String? ?? 'Occasion',
      location: row['location'] as String? ?? 'Libreville',
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String),
      quantity: row['quantity'] as int? ?? 1,
      published: row['published'] as bool? ?? true,
    );
  }

  /// Helper: Parse products from JSON (cache)
  List<Product> _parseProductsFromJson(dynamic json) {
    if (json is List) {
      return json.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
