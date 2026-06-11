import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// ✅ Service sécurisé pour stocker données sensibles
/// Utilise le stockage natif sécurisé du device:
/// - iOS: Keychain
/// - Android: KeyStore
/// - Windows: Data Protection API
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );
  
  /// Sauvegarder un token sécurisé (Access token, Refresh token, etc.)
  static Future<void> saveToken(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      debugPrint('✅ Token sauvegardé: $key');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde token: $e');
      rethrow;
    }
  }
  
  /// Récupérer un token sécurisé
  static Future<String?> getToken(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) {
        debugPrint('✅ Token récupéré: $key');
      }
      return value;
    } catch (e) {
      debugPrint('❌ Erreur lecture token: $e');
      return null;
    }
  }
  
  /// Supprimer un token
  static Future<void> deleteToken(String key) async {
    try {
      await _storage.delete(key: key);
      debugPrint('✅ Token supprimé: $key');
    } catch (e) {
      debugPrint('❌ Erreur suppression token: $e');
    }
  }
  
  /// Vider tout le stockage sécurisé (logout)
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      debugPrint('✅ Stockage sécurisé vidé (logout)');
    } catch (e) {
      debugPrint('❌ Erreur vidage stockage: $e');
    }
  }
  
  /// Vérifier si un token existe
  static Future<bool> hasToken(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      return false;
    }
  }
}
