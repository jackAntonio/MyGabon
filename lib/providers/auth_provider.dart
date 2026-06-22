import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_token_service.dart';
import '../services/secure_storage_service.dart';
import '../app_services.dart';
import 'dart:async';

/// ✅ SÉCURISÉ: Authentification avec Firebase Auth + JWT Tokens
/// Gère login, registration, token refresh et logout
class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  late final AuthTokenService _tokenService;
  
  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  String? _errorMessage;
  bool _isLoading = false;
  
  AuthProvider({String? jwtSecret}) {
    // Initialiser token service avec une clé sécurisée
    final secret = jwtSecret ?? _getDefaultSecret();
    _tokenService = AuthTokenService(jwtSecret: secret);
    
    // Vérifier auth status au démarrage
    _checkAuthStatus();
  }
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get accessToken => _accessToken;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  
  /// ✅ Login avec email et mot de passe
  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (password.isEmpty || emailOrPhone.isEmpty) {
        throw Exception('Email/Téléphone et mot de passe requis');
      }
      
      // Login avec Firebase Auth
      String email = emailOrPhone;
      if (_isPhoneNumber(emailOrPhone)) {
        // TODO: Implémenter lookup email à partir du téléphone
        throw Exception('Authentification téléphone non encore implémentée');
      }
      
      final credentials = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credentials.user == null) {
        throw Exception('Authentification échouée');
      }
      
      _currentUser = credentials.user;
      
      // Générer tokens
      await _generateAndSaveTokens(_currentUser!.uid, _currentUser!.email!);

      // 📝 Log audit
      await AppServices().auditLog.logLogin(
        email: _currentUser!.email!,
        success: true,
      );

      debugPrint('✅ Login réussi: ${_currentUser!.email}');
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      _setError('Erreur authentification: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  /// ✅ Registration avec validation
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Validation
      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        throw Exception('Tous les champs sont requis');
      }
      
      if (password.length < 8) {
        throw Exception('Mot de passe minimum 8 caractères');
      }
      
      // Créer user Firebase
      final credentials = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credentials.user == null) {
        throw Exception('Création compte échouée');
      }
      
      // Mettre à jour profile
      await credentials.user!.updateDisplayName(fullName);
      await credentials.user!.updatePhotoURL(''); // Avatar placeholder
      
      _currentUser = credentials.user;
      
      // Générer tokens
      await _generateAndSaveTokens(_currentUser!.uid, email);

      debugPrint('✅ Registration réussi: $email');
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      _setError('Erreur inscription: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  /// ✅ Refresh access token avec refresh token
  Future<bool> refreshAccessToken() async {
    try {
      final storedRefreshToken = await SecureStorageService.getToken('refresh_token');
      
      if (storedRefreshToken == null) {
        await logout();
        return false;
      }
      
      // Vérifier refresh token
      if (!_tokenService.verifyToken(storedRefreshToken)) {
        await logout();
        return false;
      }
      
      final userId = _tokenService.getUserIdFromToken(storedRefreshToken);
      if (userId == null || _currentUser?.email == null) {
        return false;
      }
      
      // Générer nouvel access token
      _accessToken = _tokenService.generateAccessToken(
        userId: userId,
        email: _currentUser!.email!,
      );
      
      await SecureStorageService.saveToken('access_token', _accessToken!);
      
      debugPrint('✅ Access token rafraîchi');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erreur refresh token: $e');
      return false;
    }
  }
  
  /// ✅ Logout sécurisé
  Future<void> logout() async {
    try {
      _setLoading(true);

      // 📝 Log audit
      await AppServices().auditLog.logLogout();

      // Supprimer tokens stockés
      await SecureStorageService.clearAll();

      // Logout Firebase
      await _auth.signOut();

      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;

      debugPrint('✅ Logout réussi');
      notifyListeners();
    } catch (e) {
      _setError('Erreur logout: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  /// ✅ Reset mot de passe
  Future<void> resetPassword({required String email}) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (email.isEmpty) {
        throw Exception('Email requis');
      }
      
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Email de reset envoyé à: $email');
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      _setError('Erreur: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // --- PRIVATE METHODS ---
  
  /// Générer et sauvegarder tokens
  Future<void> _generateAndSaveTokens(String userId, String email) async {
    _accessToken = _tokenService.generateAccessToken(
      userId: userId,
      email: email,
    );
    
    _refreshToken = _tokenService.generateRefreshToken(userId: userId);
    
    // Sauvegarder tokens dans stockage sécurisé
    await SecureStorageService.saveToken('access_token', _accessToken!);
    await SecureStorageService.saveToken('refresh_token', _refreshToken!);
  }
  
  /// Vérifier status auth au démarrage
  Future<void> _checkAuthStatus() async {
    try {
      _currentUser = _auth.currentUser;
      
      if (_currentUser != null) {
        final storedAccessToken = await SecureStorageService.getToken('access_token');
        
        if (storedAccessToken != null && _tokenService.verifyToken(storedAccessToken)) {
          _accessToken = storedAccessToken;
          debugPrint('✅ Session restaurée: ${_currentUser!.email}');
        } else {
          // Essayer de rafraîchir
          await refreshAccessToken();
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur vérification auth: $e');
    }
  }
  
  /// Gérer erreurs Firebase
  void _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        _setError('Utilisateur non trouvé');
        break;
      case 'wrong-password':
        _setError('Mot de passe incorrect');
        break;
      case 'email-already-in-use':
        _setError('Cet email est déjà utilisé');
        break;
      case 'weak-password':
        _setError('Mot de passe trop faible (min. 8 caractères)');
        break;
      case 'invalid-email':
        _setError('Format email invalide');
        break;
      case 'account-exists-with-different-credential':
        _setError('Un compte existe avec ce email');
        break;
      case 'operation-not-allowed':
        _setError('Authentification non activée');
        break;
      case 'too-many-requests':
        _setError('Trop de tentatives. Réessayez plus tard');
        break;
      default:
        _setError('Erreur authentification: ${e.message}');
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    debugPrint('❌ $message');
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
  
  bool _isPhoneNumber(String value) {
    return value.startsWith('+') || value.length >= 9;
  }
  
  /// Clé par défaut (à remplacer par variable d'environnement en production)
  String _getDefaultSecret() {
    // ⚠️ EN PRODUCTION: Charger depuis .env ou secrets manager
    return 'default-jwt-secret-minimum-32-chars-required-for-production';
  }
}

