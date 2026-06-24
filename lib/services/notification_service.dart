import 'package:flutter/foundation.dart';

/// Service de notifications push.
/// ⚠️ Pas de backend de push configuré pour l'instant (ni Firebase Cloud
/// Messaging, ni alternative) : ce service est un stub honnête plutôt que
/// d'appeler une dépendance Firebase non déclarée. À implémenter quand un
/// fournisseur de push sera choisi (FCM, OneSignal, ou Supabase + APNs/FCM
/// directs).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  bool _initialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('ℹ️ NotificationService: push non configuré (stub)');
  }

  Future<void> subscribeToTopic(String topic) async {
    debugPrint('ℹ️ subscribeToTopic($topic) ignoré : push non configuré');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('ℹ️ unsubscribeFromTopic($topic) ignoré : push non configuré');
  }

  Future<String?> getFCMToken() async => null;
}
