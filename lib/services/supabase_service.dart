import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// ✅ Service Supabase - Backend principal pour GabonConnect
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  late final SupabaseClient _client;
  bool _initialized = false;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  /// Initialiser Supabase
  Future<void> init({
    required String url,
    required String anonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      _client = Supabase.instance.client;
      _initialized = true;
      debugPrint('✅ Supabase initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur initialisation Supabase: $e');
      rethrow;
    }
  }

  // ========== AUTHENTICATION ==========

  /// Sign up avec email et password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      // Créer profil utilisateur
      if (response.user != null) {
        await _createUserProfile(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
        );

        // Log audit
        await logAuditEvent(
          action: 'user_created',
          details: {'email': email},
        );
      }

      return response;
    } catch (e) {
      debugPrint('❌ Erreur sign up: $e');
      rethrow;
    }
  }

  /// Sign in avec email et password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Log audit
      await logAuditEvent(
        action: 'login',
        details: {'email': email, 'success': true},
      );

      return response;
    } catch (e) {
      debugPrint('❌ Erreur sign in: $e');

      // Log failed attempt
      await logAuditEvent(
        action: 'login_failed',
        details: {'email': email, 'error': e.toString()},
      );

      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await logAuditEvent(action: 'logout');
      await _client.auth.signOut();
      debugPrint('✅ Logged out');
    } catch (e) {
      debugPrint('❌ Erreur sign out: $e');
    }
  }

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if authenticated
  bool get isAuthenticated => currentUser != null;

  // ========== USER MANAGEMENT ==========

  /// Créer profil utilisateur dans Firestore
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    try {
      await _client.from('users').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
      });
      debugPrint('✅ User profile créé');
    } catch (e) {
      debugPrint('⚠️ Erreur création profile: $e');
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return data;
    } catch (e) {
      debugPrint('❌ Erreur récupération profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _client.from('users').update(updates).eq('id', userId);

      debugPrint('✅ Profile mis à jour');
    } catch (e) {
      debugPrint('❌ Erreur update profile: $e');
      rethrow;
    }
  }

  // ========== OTP & VERIFICATION (Phase 2) ==========

  /// Envoyer OTP par SMS
  Future<bool> sendOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      // Sauvegarder OTP en base
      await _client.from('otp_logs').insert({
        'phone_number': phoneNumber,
        'otp_code': otp,
        'attempts': 0,
      });

      // TODO: Appeler Twilio ou Edge Function pour envoyer SMS réel
      // Pour l'instant: simulation
      debugPrint('📱 OTP simulé envoyé: $otp à $phoneNumber');

      return true;
    } catch (e) {
      debugPrint('❌ Erreur envoi OTP: $e');
      return false;
    }
  }

  /// Vérifier OTP
  Future<bool> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final result = await _client
          .from('user_verifications')
          .update({'verified': true, 'verified_at': DateTime.now().toIso8601String()})
          .eq('phone_number', phoneNumber)
          .eq('otp_code', otp)
          .eq('verified', false);

      if (result.isEmpty) {
        throw Exception('OTP invalide ou expiré');
      }

      // Log verification
      await logAuditEvent(
        action: 'phone_verified',
        details: {'phone': _maskPhone(phoneNumber)},
      );

      return true;
    } catch (e) {
      debugPrint('❌ Erreur vérification OTP: $e');
      return false;
    }
  }

  // ========== AUDIT LOGGING (Phase 2) ==========

  /// Logger une action
  Future<void> logAuditEvent({
    required String action,
    String? resource,
    String? resourceId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _client.from('audit_logs').insert({
        'user_id': currentUser?.id,
        'action': action,
        'resource': resource,
        'resource_id': resourceId,
        'details': details,
        'status': 'success',
      });

      debugPrint('📝 Audit logged: $action');
    } catch (e) {
      debugPrint('⚠️ Erreur audit logging: $e');
      // Ne pas throw - c'est un log, pas critique
    }
  }

  /// Récupérer audit logs pour user
  Future<List<Map<String, dynamic>>> getAuditLogs({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final logs = await _client
          .from('audit_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(logs);
    } catch (e) {
      debugPrint('❌ Erreur récupération logs: $e');
      return [];
    }
  }

  // ========== SERVICES ==========

  /// Créer un service
  Future<String?> createService({
    required String title,
    required String description,
    required double price,
    required String category,
    String? imageUrl,
  }) async {
    try {
      final result = await _client
          .from('services')
          .insert({
            'provider_id': currentUser!.id,
            'title': title,
            'description': description,
            'price': price,
            'category': category,
            'image_url': imageUrl,
          })
          .select()
          .single();

      await logAuditEvent(
        action: 'service_created',
        resourceId: result['id'],
        details: {'title': title, 'category': category},
      );

      return result['id'];
    } catch (e) {
      debugPrint('❌ Erreur création service: $e');
      return null;
    }
  }

  /// Récupérer services
  Future<List<Map<String, dynamic>>> getServices({
    String? category,
    int limit = 20,
  }) async {
    try {
      var query = _client
          .from('services')
          .select()
          .eq('published', true)
          .limit(limit);

      if (category != null) {
        query = query.eq('category', category);
      }

      query = query.order('created_at', ascending: false);

      final services = await query;
      return List<Map<String, dynamic>>.from(services);
    } catch (e) {
      debugPrint('❌ Erreur récupération services: $e');
      return [];
    }
  }

  // ========== MESSAGES / CHAT ==========

  /// Envoyer message
  Future<bool> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      await _client.from('messages').insert({
        'sender_id': currentUser!.id,
        'receiver_id': receiverId,
        'content': content,
      });

      await logAuditEvent(
        action: 'message_sent',
        details: {'receiver': receiverId},
      );

      return true;
    } catch (e) {
      debugPrint('❌ Erreur envoi message: $e');
      return false;
    }
  }

  /// Subscribe to messages realtime
  void subscribeToMessages({
    required String userId,
    required Function(Map<String, dynamic>) onNewMessage,
  }) {
    _client
        .from('messages')
        .on(RealtimeEventTypes.insert, (payload) {
          final message = payload.newRecord;
          if (message['sender_id'] == userId || message['receiver_id'] == userId) {
            onNewMessage(message);
          }
        })
        .subscribe();

    debugPrint('📡 Subscribed to messages');
  }

  // ========== HELPER METHODS ==========

  /// Masquer numéro de téléphone pour logs
  String _maskPhone(String phone) {
    if (phone.length < 4) return '****';
    return '*' * (phone.length - 4) + phone.substring(phone.length - 4);
  }

  /// Vérifier connexion Supabase
  bool get isConnected => _initialized && currentUser != null;
}

/// Instance globale
final supabaseService = SupabaseService();
