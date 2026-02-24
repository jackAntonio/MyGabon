import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

/// Service for caching data locally using Hive
/// Enables offline access to previously loaded services and products
class CacheService {
  static const String servicesBoxName = 'services_cache';
  static const String productsBoxName = 'products_cache';
  static const String usersBoxName = 'users_cache';
  static const String cacheMetaBoxName = 'cache_metadata';
  
  static late Box<dynamic> _servicesBox;
  static late Box<dynamic> _productsBox;
  static late Box<dynamic> _usersBox;
  static late Box<Map<dynamic, dynamic>> _metaBox;
  
  static bool _initialized = false;
  
  /// Initialize Hive and open all boxes
  static Future<void> init() async {
    if (_initialized) return;
    
    try {
      await Hive.initFlutter();
      
      _servicesBox = await Hive.openBox(servicesBoxName);
      _productsBox = await Hive.openBox(productsBoxName);
      _usersBox = await Hive.openBox(usersBoxName);
      _metaBox = await Hive.openBox<Map<dynamic, dynamic>>(cacheMetaBoxName);
      
      _initialized = true;
      debugPrint('✅ Cache service initialisé');
      
      // Clean up old cached data
      _cleanupExpiredCache();
    } catch (e) {
      debugPrint('❌ Erreur initialisation cache: $e');
    }
  }
  
  /// Cache services data with timestamp for expiration tracking
  static Future<void> cacheServices(String key, dynamic data) async {
    try {
      await _servicesBox.put(key, data);
      
      // Store metadata (timestamp, size)
      final metadata = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'size': data.toString().length,
      };
      await _metaBox.put('${servicesBoxName}_$key', metadata);
      
      debugPrint('💾 Services mises en cache: $key');
    } catch (e) {
      debugPrint('❌ Erreur mise en cache services: $e');
    }
  }
  
  /// Retrieve cached services
  static dynamic getServices(String key) {
    try {
      if (!_servicesBox.containsKey(key)) return null;
      
      // Check if cache is expired (24 hours)
      final metadata = _metaBox.get('${servicesBoxName}_$key');
      if (metadata != null) {
        final cacheTime = metadata['timestamp'] as int?;
        final now = DateTime.now().millisecondsSinceEpoch;
        final ageMs = now - (cacheTime ?? 0);
        
        if (ageMs > 24 * 60 * 60 * 1000) {
          debugPrint('🗑️ Cache expiré: $key');
          _servicesBox.delete(key);
          return null;
        }
      }
      
      return _servicesBox.get(key);
    } catch (e) {
      debugPrint('❌ Erreur lecture cache services: $e');
      return null;
    }
  }
  
  /// Cache products with expiration
  static Future<void> cacheProducts(String key, dynamic data) async {
    try {
      await _productsBox.put(key, data);
      
      final metadata = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'size': data.toString().length,
      };
      await _metaBox.put('${productsBoxName}_$key', metadata);
      
      debugPrint('💾 Produits mis en cache: $key');
    } catch (e) {
      debugPrint('❌ Erreur mise en cache produits: $e');
    }
  }
  
  /// Retrieve cached products
  static dynamic getProducts(String key) {
    try {
      if (!_productsBox.containsKey(key)) return null;
      
      final metadata = _metaBox.get('${productsBoxName}_$key');
      if (metadata != null) {
        final cacheTime = metadata['timestamp'] as int?;
        final now = DateTime.now().millisecondsSinceEpoch;
        final ageMs = now - (cacheTime ?? 0);
        
        if (ageMs > 24 * 60 * 60 * 1000) {
          debugPrint('🗑️ Cache produits expiré: $key');
          _productsBox.delete(key);
          return null;
        }
      }
      
      return _productsBox.get(key);
    } catch (e) {
      debugPrint('❌ Erreur lecture cache produits: $e');
      return null;
    }
  }
  
  /// Cache user profile
  static Future<void> cacheUser(String userId, dynamic userData) async {
    try {
      await _usersBox.put(userId, userData);
      
      final metadata = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await _metaBox.put('${usersBoxName}_$userId', metadata);
      
      debugPrint('💾 Profil utilisateur mis en cache: $userId');
    } catch (e) {
      debugPrint('❌ Erreur mise en cache utilisateur: $e');
    }
  }
  
  /// Get cached user
  static dynamic getCachedUser(String userId) {
    try {
      if (!_usersBox.containsKey(userId)) return null;
      
      final metadata = _metaBox.get('${usersBoxName}_$userId');
      if (metadata != null) {
        final cacheTime = metadata['timestamp'] as int?;
        final now = DateTime.now().millisecondsSinceEpoch;
        final ageMs = now - (cacheTime ?? 0);
        
        // User data expires after 7 days
        if (ageMs > 7 * 24 * 60 * 60 * 1000) {
          debugPrint('🗑️ Cache utilisateur expiré: $userId');
          _usersBox.delete(userId);
          return null;
        }
      }
      
      return _usersBox.get(userId);
    } catch (e) {
      debugPrint('❌ Erreur lecture cache utilisateur: $e');
      return null;
    }
  }
  
  /// Clear specific cache
  static Future<void> clearCache(String boxName, String key) async {
    try {
      switch (boxName) {
        case servicesBoxName:
          await _servicesBox.delete(key);
          break;
        case productsBoxName:
          await _productsBox.delete(key);
          break;
        case usersBoxName:
          await _usersBox.delete(key);
          break;
      }
      debugPrint('🗑️ Cache supprimé: $boxName/$key');
    } catch (e) {
      debugPrint('❌ Erreur suppression cache: $e');
    }
  }
  
  /// Clear all caches
  static Future<void> clearAllCaches() async {
    try {
      await _servicesBox.clear();
      await _productsBox.clear();
      await _usersBox.clear();
      await _metaBox.clear();
      
      debugPrint('🗑️ Tous les caches sont vidés');
    } catch (e) {
      debugPrint('❌ Erreur vidage caches: $e');
    }
  }
  
  /// Get cache statistics
  static Map<String, int> getCacheStats() {
    return {
      'services': _servicesBox.length,
      'products': _productsBox.length,
      'users': _usersBox.length,
    };
  }
  
  /// Clean up expired cache entries (cleanup intervals)
  static Future<void> _cleanupExpiredCache() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expirationMs = 24 * 60 * 60 * 1000; // 24 hours
      
      // Clean services cache
      final expiredServices = <String>[];
      _servicesBox.keys.forEach((key) {
        final metadata = _metaBox.get('${servicesBoxName}_$key');
        if (metadata != null) {
          final cacheTime = metadata['timestamp'] as int?;
          if (now - (cacheTime ?? 0) > expirationMs) {
            expiredServices.add(key as String);
          }
        }
      });
      
      for (final key in expiredServices) {
        await _servicesBox.delete(key);
      }
      
      if (expiredServices.isNotEmpty) {
        debugPrint('🧹 ${expiredServices.length} entrées de cache expirées supprimées');
      }
    } catch (e) {
      debugPrint('❌ Erreur nettoyage cache: $e');
    }
  }
}
