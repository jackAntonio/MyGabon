import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Service de notifications push (OneSignal — cf.
/// SUPABASE_VS_FIREBASE_DECISION.md : le projet a explicitement écarté
/// Firebase, OneSignal évite de réintroduire son SDK juste pour le push).
///
/// OneSignal associe les appareils à un "external user id" (ici l'id
/// Supabase de l'utilisateur connecté) : pas besoin de table de tokens
/// côté Supabase, le backend cible directement cet id via l'API REST
/// OneSignal (cf. supabase/functions/send-push-notification).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  bool _initialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    if (_initialized) return;

    // Le SDK OneSignal Flutter ne supporte que iOS/Android (MissingPluginException
    // non rattrapable sur web, qui plante tout l'arbre de widgets avant le
    // premier rendu) : on n'initialise jamais sur web.
    if (kIsWeb) {
      debugPrint(
          'ℹ️ NotificationService: push non supporté sur web, désactivé');
      return;
    }

    const appId = String.fromEnvironment('ONESIGNAL_APP_ID');
    if (appId.isEmpty) {
      debugPrint(
          'ℹ️ NotificationService: ONESIGNAL_APP_ID manquant (push désactivé)');
      return;
    }

    try {
      OneSignal.initialize(appId);
      await OneSignal.Notifications.requestPermission(true);
      _initialized = true;
    } catch (e) {
      debugPrint('⚠️ NotificationService: échec initialisation OneSignal: $e');
    }
  }

  /// Associe l'utilisateur connecté à son abonnement push (à appeler après
  /// chaque connexion réussie).
  Future<void> login(String userId) async {
    if (!_initialized) return;
    try {
      await OneSignal.login(userId);
    } catch (e) {
      debugPrint('⚠️ NotificationService: échec login OneSignal: $e');
    }
  }

  /// Dissocie l'appareil de l'utilisateur (à appeler à la déconnexion, pour
  /// qu'il ne reçoive plus de push destinés à ce compte).
  Future<void> logout() async {
    if (!_initialized) return;
    try {
      await OneSignal.logout();
    } catch (e) {
      debugPrint('⚠️ NotificationService: échec logout OneSignal: $e');
    }
  }
}
