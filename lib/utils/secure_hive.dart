import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Ouvre des box Hive chiffrées (AES-256) pour les données personnelles
/// stockées localement (vérification d'identité, cache de profils...).
/// La clé est générée une seule fois puis conservée dans le stockage
/// sécurisé natif (Keychain iOS / Keystore Android), jamais en clair sur le
/// disque comme le serait une box Hive non chiffrée.
class SecureHive {
  static const _storage = FlutterSecureStorage();
  static const _keyPrefix = 'hive_aes_key_';

  static Future<HiveAesCipher> _cipherFor(String boxName) async {
    final storageKey = '$_keyPrefix$boxName';
    final stored = await _storage.read(key: storageKey);
    List<int> key;
    if (stored == null) {
      key = Hive.generateSecureKey();
      await _storage.write(key: storageKey, value: base64UrlEncode(key));
    } else {
      key = base64Url.decode(stored);
    }
    return HiveAesCipher(key);
  }

  static Future<Box<T>> openEncryptedBox<T>(String boxName) async {
    final cipher = await _cipherFor(boxName);
    try {
      return await Hive.openBox<T>(boxName, encryptionCipher: cipher);
    } catch (_) {
      // Box existante non chiffrée (créée avant ce correctif) : impossible à
      // déchiffrer avec la nouvelle clé, on la recrée chiffrée. Ce sont des
      // données locales dérivées (cache, queue, stats), jamais la source de
      // vérité (qui reste dans Supabase).
      await Hive.deleteBoxFromDisk(boxName);
      return Hive.openBox<T>(boxName, encryptionCipher: cipher);
    }
  }
}
