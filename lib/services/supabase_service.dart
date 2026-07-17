import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'secure_local_storage.dart';

/// ✅ Service Supabase - Backend principal pour GabonConnect
class SupabaseService {
  // ⚠️ Sans ce paramètre explicite, Supabase utilise le "Site URL" du
  // dashboard pour les liens de confirmation email / reset mot de passe —
  // qui vaut http://localhost:3000 par défaut sur un nouveau projet (rien
  // n'y répond pour une app mobile). Ce schéma doit être déclaré dans
  // android/app/src/main/AndroidManifest.xml (et ios/Runner/Info.plist) ET
  // ajouté aux Redirect URLs autorisées dans Supabase Dashboard >
  // Authentication > URL Configuration (sinon Supabase rejette le lien).
  static const _authRedirectUrl = 'mygabon://login-callback';

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
        authOptions: FlutterAuthClientOptions(
          // ✅ Session (refresh token inclus) chiffrée via flutter_secure_storage
          // au lieu du SharedPreferences en clair par défaut.
          localStorage: SecureLocalStorage(
            persistSessionKey:
                'sb-${Uri.parse(url).host.split(".").first}-auth-token',
          ),
        ),
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
    String? phoneNumber,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _authRedirectUrl,
        data: {'full_name': fullName},
      );

      // Créer profil utilisateur — seulement si une session est active : sans
      // elle, auth.uid() est NULL et la policy RLS INSERT sur `users` rejette
      // la ligne (cas où la confirmation email est activée sur le projet :
      // signUp() crée bien le compte mais ne connecte personne). Le profil
      // est alors créé au premier login confirmé, cf. ensureUserProfile.
      if (response.user != null && response.session != null) {
        await _createUserProfile(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
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

  /// Crée la ligne de profil si elle n'existe pas encore (rattrape le cas où
  /// signUp() n'a pas pu le faire faute de session active — confirmation
  /// email requise). Idempotent, à appeler à chaque connexion réussie.
  Future<void> ensureUserProfile() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final existing = await _client
          .from('users')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (existing != null) return;

      await _createUserProfile(
        userId: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('⚠️ Erreur vérification/création profile: $e');
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

  /// Demander un email de réinitialisation de mot de passe
  Future<void> resetPassword({required String email}) async {
    await _client.auth
        .resetPasswordForEmail(email, redirectTo: _authRedirectUrl);
    await logAuditEvent(
        action: 'password_reset_requested', details: {'email': email});
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

  /// Client Supabase partagé, pour les services de domaine (reviews,
  /// fraud reports...) qui n'ont pas besoin d'une méthode dédiée ici.
  SupabaseClient get client => _client;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if authenticated
  bool get isAuthenticated => currentUser != null;

  // ========== USER MANAGEMENT ==========

  /// Créer profil utilisateur dans la table users
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      await _client.from('users').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      });
      debugPrint('✅ User profile créé');
    } catch (e) {
      debugPrint('⚠️ Erreur création profile: $e');
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final data =
          await _client.from('users').select().eq('id', userId).single();

      return data;
    } catch (e) {
      debugPrint('❌ Erreur récupération profile: $e');
      return null;
    }
  }

  /// Update user profile.
  /// ✅ Paramètres nommés explicites (pas de Map générique) : seules ces
  /// colonnes peuvent être modifiées par ce point d'entrée. C'est aussi
  /// imposé côté base (GRANT UPDATE limité, cf. migration
  /// 20260624_security_hardening.sql) : verified/rating/email/id ne
  /// peuvent être changés que par des RPC dédiées.
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
  }) async {
    final updates = <String, dynamic>{
      if (fullName != null) 'full_name': fullName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bio != null) 'bio': bio,
    };
    if (updates.isEmpty) return;
    try {
      await _client.from('users').update(updates).eq('id', userId);

      debugPrint('✅ Profile mis à jour');
    } catch (e) {
      debugPrint('❌ Erreur update profile: $e');
      rethrow;
    }
  }

  // ========== OTP & VERIFICATION (Phase 2) ==========
  // ✅ L'OTP est généré, haché et vérifié exclusivement côté serveur. La
  // génération + l'envoi SMS réel passent par l'Edge Function send-otp-sms
  // (seul endroit où les credentials Twilio peuvent rester côté serveur) ;
  // la vérification reste le RPC confirm_phone_otp (SECURITY DEFINER). Le
  // client ne voit jamais le code et ne peut pas positionner
  // users.verified lui-même (cf. migrations 20260624_security_hardening.sql
  // et 20260628_drop_legacy_request_phone_otp.sql).

  /// Demander l'envoi d'un OTP par SMS au numéro donné
  Future<bool> sendOTP({required String phoneNumber}) async {
    try {
      final response = await _client.functions.invoke('send-otp-sms', body: {
        'phoneNumber': phoneNumber,
      });
      final data = response.data as Map<String, dynamic>?;
      return data?['success'] == true;
    } catch (e) {
      debugPrint('❌ Erreur envoi OTP: $e');
      return false;
    }
  }

  /// Vérifier l'OTP saisi par l'utilisateur ; positionne users.verified
  /// côté serveur en cas de succès.
  Future<bool> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final success = await _client.rpc('confirm_phone_otp', params: {
        'p_phone_number': phoneNumber,
        'p_code': otp,
      }) as bool;

      if (success) {
        await logAuditEvent(
          action: 'phone_verified',
          details: {'phone': _maskPhone(phoneNumber)},
        );
      }

      return success;
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
    required String location,
    String? imageUrl,
    double? latitude,
    double? longitude,
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
            'location': location,
            'latitude': latitude,
            'longitude': longitude,
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

  /// Récupérer services publiés, page par page, avec le profil du
  /// prestataire (nom, note, vérifié) attaché depuis `profiles_public`.
  Future<List<Map<String, dynamic>>> getServices({
    String? category,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _client.from('services').select().eq('published', true);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final services = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, page * pageSize + pageSize - 1);
      return _attachPublicProfiles(
        List<Map<String, dynamic>>.from(services),
        idField: 'provider_id',
        attachAs: 'provider',
      );
    } catch (e) {
      debugPrint('❌ Erreur récupération services: $e');
      return [];
    }
  }

  /// Attache le profil public (`profiles_public` : nom, avatar, note,
  /// vérifié — jamais email/téléphone) de [idField] sous la clé [attachAs].
  /// Nécessaire car `users` est verrouillée par RLS à `auth.uid() = id` : un
  /// embed PostgREST direct (`select('*, users!fk(...)')`) ne renverrait
  /// le profil que pour ses propres lignes, jamais celles des autres
  /// vendeurs/prestataires (cf. CREATE POLICY "Users can read own row").
  /// `profiles_public` existe précisément pour contourner cette
  /// restriction de façon contrôlée (vue créée par
  /// 20260623_wallet_rpc_and_public_profiles.sql, colonnes limitées).
  Future<List<Map<String, dynamic>>> _attachPublicProfiles(
    List<Map<String, dynamic>> rows, {
    required String idField,
    required String attachAs,
  }) async {
    final ids = rows.map((r) => r[idField] as String).toSet().toList();
    if (ids.isEmpty) return rows;

    final profiles =
        await _client.from('profiles_public').select().inFilter('id', ids);
    final byId = {
      for (final p in List<Map<String, dynamic>>.from(profiles))
        p['id'] as String: p
    };

    for (final row in rows) {
      row[attachAs] = byId[row[idField]];
    }
    return rows;
  }

  // ========== MESSAGES / CHAT ==========

  /// Envoyer message
  Future<bool> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      final inserted = await _client
          .from('messages')
          .insert({
            'sender_id': currentUser!.id,
            'receiver_id': receiverId,
            'content': content,
          })
          .select('id')
          .single();

      await logAuditEvent(
        action: 'message_sent',
        details: {'receiver': receiverId},
      );

      _notifyNewMessage(inserted['id'] as String);

      return true;
    } catch (e) {
      debugPrint('❌ Erreur envoi message: $e');
      return false;
    }
  }

  /// Déclenche une notification push (OneSignal) pour le destinataire, en
  /// best-effort : un échec d'envoi push ne doit jamais faire échouer
  /// l'envoi du message lui-même (cf. send-push-notification/index.ts).
  void _notifyNewMessage(String messageId) {
    () async {
      try {
        await _client.functions.invoke('send-push-notification', body: {
          'message_id': messageId,
        });
      } catch (e) {
        debugPrint('⚠️ Notification push non envoyée: $e');
      }
    }();
  }

  /// Récupérer le fil de messages avec un interlocuteur donné (les deux sens)
  Future<List<Map<String, dynamic>>> getMessages(String otherUserId) async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    if (!_isValidUuid(otherUserId)) return [];
    try {
      // userId vient de la session auth, otherUserId est validé ci-dessus :
      // l'interpolation dans .or() ne reçoit jamais autre chose qu'un UUID.
      final messages = await _client
          .from('messages')
          .select()
          .or('and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),'
              'and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(messages);
    } catch (e) {
      debugPrint('❌ Erreur récupération messages: $e');
      return [];
    }
  }

  /// Flux temps réel des messages envoyés par [otherUserId] à l'utilisateur
  /// courant (les messages envoyés par moi sont ajoutés en local de façon
  /// optimiste après sendMessage, pas besoin de les re-streamer).
  Stream<List<Map<String, dynamic>>> streamIncomingMessages(
      String otherUserId) {
    final userId = currentUser?.id;
    if (userId == null) return const Stream.empty();
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('sender_id', otherUserId)
        .order('created_at')
        .map((rows) => rows.where((r) => r['receiver_id'] == userId).toList());
  }

  /// Liste des conversations de l'utilisateur courant (dernier message par
  /// interlocuteur), construite côté client à partir des messages échangés.
  Future<List<Map<String, dynamic>>> getConversations() async {
    final userId = currentUser?.id;
    if (userId == null || !_isValidUuid(userId)) return [];
    try {
      final messages = await _client
          .from('messages')
          .select()
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false);

      final byOtherUser = <String, Map<String, dynamic>>{};
      for (final m in messages) {
        final otherId =
            m['sender_id'] == userId ? m['receiver_id'] : m['sender_id'];
        byOtherUser.putIfAbsent(otherId as String, () => m);
      }
      return byOtherUser.entries
          .map((e) => {'other_user_id': e.key, ...e.value})
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération conversations: $e');
      return [];
    }
  }

  /// Profil public (nom, avatar, vérifié, note) — sans email/téléphone.
  Future<Map<String, dynamic>?> getPublicProfile(String userId) async {
    try {
      return await _client
          .from('profiles_public')
          .select()
          .eq('id', userId)
          .single();
    } catch (e) {
      debugPrint('❌ Erreur récupération profil public: $e');
      return null;
    }
  }

  // ========== HELPER METHODS ==========

  /// Masquer numéro de téléphone pour logs
  String _maskPhone(String phone) {
    if (phone.length < 4) return '****';
    return '*' * (phone.length - 4) + phone.substring(phone.length - 4);
  }

  /// Valide qu'une valeur est bien un UUID avant de l'interpoler dans un
  /// filtre PostgREST (.or(...)) : empêche une valeur contenant des
  /// caractères de syntaxe de filtre (virgule, parenthèse, opérateur) de
  /// modifier la requête envoyée au serveur.
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  bool _isValidUuid(String value) => _uuidPattern.hasMatch(value);

  // ========== PRODUCTS / MARKETPLACE ==========

  /// Récupérer produits publiés, page par page, avec le profil du vendeur
  /// (nom, note, vérifié) attaché depuis `profiles_public`. [category]
  /// filtre si fourni.
  Future<List<Map<String, dynamic>>> getAllProducts({
    String? category,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _client.from('products').select().eq('published', true);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final products = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, page * pageSize + pageSize - 1);
      return _attachPublicProfiles(
        List<Map<String, dynamic>>.from(products),
        idField: 'seller_id',
        attachAs: 'seller',
      );
    } catch (e) {
      debugPrint('❌ Erreur récupération produits: $e');
      return [];
    }
  }

  /// Créer un produit
  Future<String?> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required String location,
    required int quantity,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final result = await _client
          .from('products')
          .insert({
            'seller_id': currentUser!.id,
            'title': title,
            'description': description,
            'price': price,
            'category': category,
            'condition': condition,
            'location': location,
            'latitude': latitude,
            'longitude': longitude,
            'quantity': quantity,
            'image_url': imageUrl,
            'published': true,
          })
          .select()
          .single();

      await logAuditEvent(
        action: 'product_created',
        resourceId: result['id'],
        details: {'title': title, 'category': category},
      );

      return result['id'];
    } catch (e) {
      debugPrint('❌ Erreur création produit: $e');
      return null;
    }
  }

  // ========== WALLET / TRANSACTIONS ==========

  /// Récupérer solde du portefeuille
  Future<double> getWalletBalance(String userId) async {
    if (currentUser?.id != userId) {
      throw Exception(
          'Accès refusé : vous ne pouvez consulter que votre propre portefeuille');
    }
    try {
      final result = await _client
          .from('user_wallets')
          .select('balance')
          .eq('user_id', userId)
          .single();
      return (result['balance'] as num).toDouble();
    } catch (e) {
      debugPrint('⚠️ Erreur récupération solde: $e');
      // Créer le portefeuille s'il n'existe pas encore (solde 0, jamais de
      // crédit gratuit — tout crédit réel passe par adjust_wallet_balance/
      // confirm_external_payment/confirm_wallet_topup).
      try {
        await _client.from('user_wallets').insert({
          'user_id': userId,
          'balance': 0.0,
        });
      } catch (_) {
        // Already exists or insert failed for another reason.
      }
      return 0.0;
    }
  }

  /// Récupérer les transactions de l'utilisateur
  Future<List> getUserTransactions(String userId) async {
    if (currentUser?.id != userId) {
      throw Exception(
          'Accès refusé : vous ne pouvez consulter que vos propres transactions');
    }
    if (!_isValidUuid(userId)) return [];
    try {
      // userId est validé ci-dessus : l'interpolation dans .or() ne reçoit
      // jamais autre chose qu'un UUID.
      final transactions = await _client
          .from('transactions')
          .select()
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(50);
      return transactions as List;
    } catch (e) {
      debugPrint('❌ Erreur récupération transactions: $e');
      return [];
    }
  }

  /// Commandes de l'utilisateur (achats et ventes) enrichies du titre/de
  /// l'image du produit et du nom de la contrepartie, pour l'écran "Mes
  /// commandes" — getUserTransactions() ne renvoie que les lignes brutes.
  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    final rows = await getUserTransactions(userId);
    var orders = List<Map<String, dynamic>>.from(rows);
    if (orders.isEmpty) return orders;

    final productIds = orders.map((o) => o['product_id'] as String).toSet().toList();
    final products = await _client
        .from('products')
        .select('id, title, image_url')
        .inFilter('id', productIds);
    final productById = {
      for (final p in List<Map<String, dynamic>>.from(products))
        p['id'] as String: p
    };
    for (final order in orders) {
      order['product'] = productById[order['product_id']];
    }

    orders = await _attachPublicProfiles(orders,
        idField: 'buyer_id', attachAs: 'buyer');
    orders = await _attachPublicProfiles(orders,
        idField: 'seller_id', attachAs: 'seller');
    return orders;
  }

  /// Notifications de l'utilisateur connecté (centre de notifications
  /// in-app), les plus récentes d'abord.
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    try {
      final result = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ Erreur récupération notifications: $e');
      return [];
    }
  }

  /// Marquer une notification comme lue.
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'read': true}).eq('id', notificationId);
    } catch (e) {
      debugPrint('❌ Erreur marquage notification lue: $e');
    }
  }

  /// Créer une transaction
  Future<String?> createTransaction({
    required String sellerId,
    required String productId,
    required double grossAmount,
    required String paymentMethod,
    double deliveryFee = 0,
  }) async {
    try {
      // ⚠️ Ces montants ne sont qu'indicatifs côté client : un trigger
      // serveur (enforce_transaction_pricing, migration
      // 20260626_enforce_transaction_pricing.sql) les recalcule depuis
      // products.price à l'INSERT — un client modifié ne peut pas créer
      // une transaction à un prix arbitraire.
      final visibleFee = grossAmount * 0.05;
      final actualFee = grossAmount * 0.05;
      final netToSeller = grossAmount * 0.95;

      final result = await _client
          .from('transactions')
          .insert({
            'buyer_id': currentUser!.id,
            'seller_id': sellerId,
            'product_id': productId,
            'gross_amount': grossAmount,
            'visible_fee': visibleFee,
            'actual_fee': actualFee,
            'net_to_seller': netToSeller,
            'payment_method': paymentMethod,
            'status': 'pending',
            'delivery_fee': deliveryFee,
            'delivery_status': deliveryFee > 0 ? 'pending' : 'none',
          })
          .select()
          .single();

      await logAuditEvent(
        action: 'transaction_created',
        resourceId: result['id'],
        details: {
          'product': productId,
          'amount': grossAmount,
          'payment_method': paymentMethod,
        },
      );

      return result['id'];
    } catch (e) {
      debugPrint('❌ Erreur création transaction: $e');
      return null;
    }
  }

  /// Paye tout le panier en une seule fois via le MyGabon Wallet (RPC
  /// complete_cart_checkout, SECURITY DEFINER) : soit toutes les lignes
  /// sont débitées/créditées, soit aucune (une seule transaction Postgres
  /// implicite) — jamais un panier payé à moitié. Lève une exception
  /// (ex: "Solde insuffisant") si ça échoue.
  Future<List<String>> completeCartCheckout(
    List<({String productId, int quantity})> items,
  ) async {
    final result = await _client.rpc('complete_cart_checkout', params: {
      'p_items': items
          .map((i) => {'product_id': i.productId, 'quantity': i.quantity})
          .toList(),
    });
    return List<String>.from(result as List);
  }

  /// Finaliser un paiement MyGabon Wallet : débite l'acheteur, crédite le
  /// vendeur et marque la transaction "success", de façon atomique côté
  /// serveur (RPC complete_marketplace_transaction).
  Future<bool> completeMarketplaceTransaction(String transactionId) async {
    try {
      await _client.rpc('complete_marketplace_transaction', params: {
        'p_transaction_id': transactionId,
      });
      return true;
    } catch (e) {
      debugPrint('❌ Erreur finalisation transaction: $e');
      return false;
    }
  }

  /// Débite le MyGabon Wallet et active un abonnement Pro/Entreprise côté
  /// serveur (RPC purchase_subscription, atomique via adjust_wallet_balance).
  /// Lève une exception (ex: "Solde insuffisant") si le débit échoue —
  /// l'appelant ne doit jamais activer le Pro localement avant que cet
  /// appel ait réussi.
  Future<Map<String, dynamic>> purchaseSubscription({
    required String tier,
    required double monthlyPrice,
  }) async {
    final result = await _client.rpc('purchase_subscription', params: {
      'p_tier': tier,
      'p_monthly_price': monthlyPrice,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  /// Lit l'abonnement courant depuis Supabase (source de vérité serveur,
  /// synchronisé entre appareils). Retourne null si l'utilisateur n'a
  /// jamais souscrit (Free par défaut).
  Future<Map<String, dynamic>?> getSubscription() async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    return _client
        .from('user_subscriptions')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  /// Annule l'abonnement courant côté serveur (repasse en Free, coupe le
  /// renouvellement). Pas de remboursement du mois en cours.
  Future<void> cancelSubscriptionServer() async {
    await _client.rpc('cancel_subscription');
  }

  /// Observe le statut d'une transaction (paiement mobile money externe,
  /// Kpay/Airtel). Le statut ne passe à 'success'/'failed' que via le
  /// webhook serveur (Edge Function kpay-webhook -> confirm_external_payment
  /// / fail_external_payment, réservées à service_role) — jamais déclenché
  /// par ce client, qui se contente d'observer.
  Stream<Map<String, dynamic>?> watchTransactionStatus(String transactionId) {
    if (!_isValidUuid(transactionId)) return const Stream.empty();
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('id', transactionId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  /// Créer une demande de recharge du MyGabon Wallet (status='pending'),
  /// avant d'appeler kpay-initiate-topup avec son id. Le montant n'est
  /// jamais modifiable une fois créé (pas de policy UPDATE pour
  /// authenticated, cf. migration 20260629_wallet_topup.sql).
  Future<String?> createWalletTopup({
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final result = await _client
          .from('wallet_topups')
          .insert({
            'user_id': currentUser!.id,
            'amount': amount,
            'payment_method': paymentMethod,
            'status': 'pending',
          })
          .select('id')
          .single();
      return result['id'] as String;
    } catch (e) {
      debugPrint('❌ Erreur création recharge wallet: $e');
      return null;
    }
  }

  /// Observe le statut d'une recharge wallet. Comme pour les transactions,
  /// le statut ne passe à 'success'/'failed' que via le webhook serveur
  /// (confirm_wallet_topup/fail_wallet_topup), jamais déclaré par ce client.
  Stream<Map<String, dynamic>?> watchWalletTopupStatus(String topupId) {
    if (!_isValidUuid(topupId)) return const Stream.empty();
    return _client
        .from('wallet_topups')
        .stream(primaryKey: ['id'])
        .eq('id', topupId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  // ========== ADMINISTRATION ==========

  /// Vérifier si l'utilisateur courant est administrateur
  Future<bool> isAdmin() async {
    final userId = currentUser?.id;
    if (userId == null) return false;
    try {
      final result = await _client
          .from('admin_users')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      return result != null;
    } catch (e) {
      debugPrint('❌ Erreur vérification admin: $e');
      return false;
    }
  }

  // ========== LIVREURS ==========

  /// Soumettre une candidature livreur (soumise à étude de dossier)
  Future<bool> submitDriverApplication({
    required String fullName,
    required String phoneNumber,
    required String vehicleType,
    String? zone,
  }) async {
    try {
      await _client.from('driver_applications').insert({
        'user_id': currentUser!.id,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'vehicle_type': vehicleType,
        'zone': zone,
      });

      await logAuditEvent(
        action: 'driver_application_submitted',
        details: {'vehicle_type': vehicleType},
      );

      return true;
    } catch (e) {
      debugPrint('❌ Erreur soumission candidature livreur: $e');
      return false;
    }
  }

  /// Récupérer la dernière candidature livreur de l'utilisateur courant
  Future<Map<String, dynamic>?> getMyDriverApplication() async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    try {
      final result = await _client
          .from('driver_applications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération candidature: $e');
      return null;
    }
  }

  /// Récupérer les candidatures en attente (admin uniquement, RLS l'impose)
  Future<List<Map<String, dynamic>>> getPendingDriverApplications() async {
    try {
      final result = await _client
          .from('driver_applications')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ Erreur récupération candidatures: $e');
      return [];
    }
  }

  /// Approuver ou refuser une candidature livreur (admin uniquement)
  Future<bool> reviewDriverApplication({
    required String applicationId,
    required bool approve,
    String? reason,
  }) async {
    try {
      await _client.rpc('review_driver_application', params: {
        'p_application_id': applicationId,
        'p_approve': approve,
        'p_reason': reason,
      });
      return true;
    } catch (e) {
      debugPrint('❌ Erreur traitement candidature: $e');
      return false;
    }
  }

  /// Récupérer tous les signalements avec les profils publics du
  /// signaleur et de l'utilisateur signalé (admin uniquement, RLS
  /// "Admins can read all reports" l'impose côté serveur).
  Future<List<Map<String, dynamic>>> getFraudReports() async {
    try {
      final result = await _client
          .from('fraud_reports')
          .select()
          .order('created_at', ascending: false);
      var rows = List<Map<String, dynamic>>.from(result);
      rows = await _attachPublicProfiles(rows,
          idField: 'reporter_id', attachAs: 'reporter');
      rows = await _attachPublicProfiles(rows,
          idField: 'suspicious_user_id', attachAs: 'suspicious_user');
      return rows;
    } catch (e) {
      debugPrint('❌ Erreur récupération signalements: $e');
      return [];
    }
  }

  /// Marquer un signalement comme vérifié (admin uniquement)
  Future<bool> verifyFraudReport(String reportId) async {
    try {
      await _client.rpc('verify_fraud_report', params: {
        'p_report_id': reportId,
      });
      return true;
    } catch (e) {
      debugPrint('❌ Erreur vérification signalement: $e');
      return false;
    }
  }

  /// Bloquer/débloquer un utilisateur signalé (admin uniquement)
  Future<bool> setUserBlocked({
    required String userId,
    required bool blocked,
    String? reason,
  }) async {
    try {
      await _client.rpc('set_user_blocked', params: {
        'p_user_id': userId,
        'p_blocked': blocked,
        'p_reason': reason,
      });
      return true;
    } catch (e) {
      debugPrint('❌ Erreur blocage utilisateur: $e');
      return false;
    }
  }

  /// Livraisons disponibles à réclamer (livreurs approuvés uniquement, RLS l'impose)
  Future<List<Map<String, dynamic>>> getAvailableDeliveries() async {
    try {
      final result = await _client
          .from('transactions')
          .select()
          .eq('delivery_status', 'pending')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ Erreur récupération livraisons disponibles: $e');
      return [];
    }
  }

  /// Mes livraisons en cours (réclamées par moi, pas encore livrées)
  Future<List<Map<String, dynamic>>> getMyDeliveries() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    try {
      final result = await _client
          .from('transactions')
          .select()
          .eq('driver_id', userId)
          .eq('delivery_status', 'claimed')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ Erreur récupération mes livraisons: $e');
      return [];
    }
  }

  /// Réclamer une livraison disponible. Lève une exception portant le motif
  /// exact renvoyé par le serveur ("Plafond d'encours espèces atteint...",
  /// "Vous ne pouvez pas livrer votre propre vente...") : un simple
  /// false laisserait le livreur sans moyen de comprendre quoi faire.
  Future<void> claimDelivery(String transactionId) async {
    await _rpcOrThrow('claim_delivery', {'p_transaction_id': transactionId});
  }

  /// Marquer une livraison effectuée : crédite 50% des frais de livraison
  /// au livreur de façon atomique côté serveur (RPC complete_delivery).
  /// Refusée côté serveur pour une commande à encaisser — voir
  /// [confirmCashOnDelivery].
  Future<void> completeDelivery(String transactionId) async {
    await _rpcOrThrow('complete_delivery', {'p_transaction_id': transactionId});
  }

  // ========== PAIEMENT À LA LIVRAISON ==========

  /// Commander en paiement à la livraison (RPC create_cash_on_delivery_order).
  /// Le serveur dérive vendeur, prix et frais depuis le produit et vérifie
  /// l'éligibilité de l'acheteur — rien n'est fait confiance au client ici.
  /// Retourne l'id de la transaction créée, ou lève avec le motif de refus.
  Future<String> createCashOnDeliveryOrder(String productId) async {
    final result = await _rpcOrThrow(
      'create_cash_on_delivery_order',
      {'p_product_id': productId},
    );
    return result as String;
  }

  /// Éligibilité de l'utilisateur courant au paiement à la livraison.
  /// Purement indicatif (l'autorité reste le serveur au moment de la
  /// commande) : sert à griser l'option avec un motif compréhensible
  /// plutôt qu'à laisser l'acheteur se heurter à une erreur en validant.
  Future<({bool eligible, String? reason})> checkCodEligibility() async {
    try {
      final result = await _client.rpc('check_cod_eligibility');
      final data = Map<String, dynamic>.from(result as Map);
      return (
        eligible: data['eligible'] == true,
        reason: data['reason'] as String?,
      );
    } catch (e) {
      debugPrint('⚠️ Erreur vérification éligibilité COD: $e');
      // En cas d'échec du pré-contrôle, on laisse l'option active : le
      // serveur refusera de toute façon si l'acheteur n'est pas éligible.
      return (eligible: true, reason: null);
    }
  }

  /// Le livreur confirme avoir encaissé les espèces à la remise : crédite le
  /// vendeur et inscrit la recette au ledger des espèces dues à MyGabon
  /// (RPC confirm_cash_on_delivery, atomique côté serveur).
  Future<void> confirmCashOnDelivery(String transactionId) async {
    await _rpcOrThrow(
      'confirm_cash_on_delivery',
      {'p_transaction_id': transactionId},
    );
  }

  /// Le livreur signale que l'acheteur n'a pas réglé à la remise : la
  /// commande est annulée et le colis retourné au vendeur.
  Future<void> reportCashOnDeliveryRefused(
    String transactionId, {
    String? reason,
  }) async {
    await _rpcOrThrow('report_cash_on_delivery_refused', {
      'p_transaction_id': transactionId,
      'p_reason': reason,
    });
  }

  /// Encours d'espèces du livreur connecté : ce qu'il a encaissé en
  /// paiement à la livraison et doit encore remettre à MyGabon, et ce qu'il
  /// lui reste avant de buter sur le plafond.
  Future<({double owed, double limit, double remaining})>
      getMyDriverCashSummary() async {
    try {
      final result = await _client.rpc('my_driver_cash_summary');
      final data = Map<String, dynamic>.from(result as Map);
      return (
        owed: (data['owed'] as num).toDouble(),
        limit: (data['limit'] as num).toDouble(),
        remaining: (data['remaining'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('⚠️ Erreur récupération encours espèces: $e');
      return (owed: 0.0, limit: 0.0, remaining: 0.0);
    }
  }

  /// (Admin) Recettes COD encaissées par les livreurs et pas encore remises
  /// à MyGabon, profil livreur attaché. La RLS "Read own or admin all cash
  /// collections" n'autorise cette lecture globale qu'aux admins — un
  /// utilisateur lambda ne verrait que ses propres lignes.
  Future<List<Map<String, dynamic>>> getOutstandingCashCollections() async {
    try {
      final rows = await _client
          .from('driver_cash_collections')
          .select()
          .eq('remitted', false)
          .order('created_at', ascending: true);
      return _attachPublicProfiles(
        List<Map<String, dynamic>>.from(rows),
        idField: 'driver_id',
        attachAs: 'driver',
      );
    } catch (e) {
      debugPrint('❌ Erreur récupération recettes à remettre: $e');
      return [];
    }
  }

  /// (Admin) Confirme la remise physique d'une recette par un livreur, ce qui
  /// libère d'autant son plafond d'encours (RPC confirm_cash_remittance,
  /// réservée aux admins côté serveur).
  Future<void> confirmCashRemittance(String collectionId) async {
    await _rpcOrThrow(
      'confirm_cash_remittance',
      {'p_collection_id': collectionId},
    );
  }

  /// Appelle une RPC en remontant le message d'erreur PostgreSQL tel quel.
  /// Les RAISE EXCEPTION des RPC sont rédigés en français et destinés à
  /// l'utilisateur ; sans ça, l'UI afficherait le `PostgrestException(...)`
  /// brut au lieu du motif.
  Future<dynamic> _rpcOrThrow(
    String function,
    Map<String, dynamic> params,
  ) async {
    try {
      return await _client.rpc(function, params: params);
    } on PostgrestException catch (e) {
      debugPrint('❌ Erreur RPC $function: ${e.message}');
      throw Exception(e.message);
    }
  }

  // ========== REVIEWS ==========

  /// Récupérer les avis pour un produit
  Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
    try {
      final reviews = await _client
          .from('reviews')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(reviews);
    } catch (e) {
      debugPrint('❌ Erreur récupération avis: $e');
      return [];
    }
  }

  /// Créer un avis
  Future<bool> createReview({
    required String productId,
    required String sellerId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _client.from('reviews').insert({
        'product_id': productId,
        'seller_id': sellerId,
        'buyer_id': currentUser!.id,
        'rating': rating,
        'comment': comment,
      });

      await logAuditEvent(
        action: 'review_created',
        resourceId: productId,
        details: {'rating': rating},
      );

      return true;
    } catch (e) {
      debugPrint('❌ Erreur création avis: $e');
      return false;
    }
  }

  /// Vérifier connexion Supabase
  bool get isConnected => _initialized && currentUser != null;
}

/// Instance globale
final supabaseService = SupabaseService();
