import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persiste la session Supabase (access + refresh token) dans le stockage
/// sécurisé natif (Keychain iOS / Keystore Android via flutter_secure_storage)
/// au lieu du SharedPreferences en clair utilisé par défaut par
/// supabase_flutter (lisible sans déchiffrement sur un device rooté/jailbreaké
/// ou dans une sauvegarde non chiffrée).
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({required this.persistSessionKey});

  final String persistSessionKey;
  static const _storage = FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return (await _storage.read(key: persistSessionKey)) != null;
  }

  @override
  Future<String?> accessToken() => _storage.read(key: persistSessionKey);

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: persistSessionKey, value: persistSessionString);
}
