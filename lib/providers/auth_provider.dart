import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

/// ✅ Authentification basée sur Supabase Auth.
/// La session et le rafraîchissement des tokens sont gérés nativement par
/// supabase_flutter (persistance sécurisée incluse) : pas de JWT maison à gérer ici.
class AuthProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  StreamSubscription<AuthState>? _authSub;

  Map<String, dynamic>? _profile;
  String? _errorMessage;
  bool _isLoading = false;

  AuthProvider() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _loadProfile();
    });
    _loadProfile();
  }

  // Getters
  User? get currentUser => _service.currentUser;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoggedIn => _service.isAuthenticated;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  String get displayName =>
      (_profile?['full_name'] as String?) ??
      currentUser?.email ??
      'Utilisateur';

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

      if (_isPhoneNumber(emailOrPhone)) {
        throw Exception(
            'Connexion par téléphone non encore disponible, utilisez votre email');
      }

      await _service.signIn(email: emailOrPhone, password: password);
      await _loadProfile();

      debugPrint('✅ Login réussi: $emailOrPhone');
    } on AuthException catch (e) {
      _setError(_translateAuthError(e));
      rethrow;
    } catch (e) {
      _setError(
          'Erreur authentification: ${e.toString().replaceFirst('Exception: ', '')}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ Inscription avec validation.
  /// Renvoie `true` si l'utilisateur est immédiatement connecté, `false` si
  /// une confirmation par email est requise avant de pouvoir se connecter
  /// (le compte est créé mais sans session active).
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        throw Exception('Tous les champs sont requis');
      }
      if (password.length < 8) {
        throw Exception('Mot de passe minimum 8 caractères');
      }

      final response = await _service.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      await _loadProfile();

      debugPrint('✅ Inscription réussie: $email');
      return response.session != null;
    } on AuthException catch (e) {
      _setError(_translateAuthError(e));
      rethrow;
    } catch (e) {
      _setError(
          'Erreur inscription: ${e.toString().replaceFirst('Exception: ', '')}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ Logout
  Future<void> logout() async {
    try {
      _setLoading(true);
      await _service.signOut();
      _profile = null;
      debugPrint('✅ Logout réussi');
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

      await _service.resetPassword(email: email);
      debugPrint('✅ Email de reset envoyé à: $email');
    } on AuthException catch (e) {
      _setError(_translateAuthError(e));
      rethrow;
    } catch (e) {
      _setError('Erreur: ${e.toString().replaceFirst('Exception: ', '')}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- PRIVATE METHODS ---

  Future<void> _loadProfile() async {
    if (!_service.isAuthenticated) {
      _profile = null;
      await NotificationService().logout();
      notifyListeners();
      return;
    }
    await _service.ensureUserProfile();
    _profile = await _service.getUserProfile(currentUser!.id);
    await NotificationService().login(currentUser!.id);
    notifyListeners();
  }

  String _translateAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Email ou mot de passe incorrect';
    }
    if (message.contains('user already registered')) {
      return 'Cet email est déjà utilisé';
    }
    if (message.contains('password should be at least')) {
      return 'Mot de passe trop faible (min. 8 caractères)';
    }
    if (message.contains('email not confirmed')) {
      return 'Email non confirmé, vérifiez votre boîte mail';
    }
    return e.message;
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
    return !value.contains('@') && (value.startsWith('+') || value.length >= 8);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
