import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// ✅ Service Firebase Cloud Messaging pour notifications push
/// Gère l'initialisation FCM, permissions, et handlers de messages
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Callbacks pour différents états de notification
  Function(RemoteMessage)? _onMessageReceived;
  Function(RemoteMessage)? _onMessageOpenedApp;
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  /// Initialiser FCM
  Future<void> init() async {
    try {
      // Demander permission utilisateur (iOS)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carryForward: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Notifications FCM autorisées');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ Notifications FCM provisoires');
      } else {
        debugPrint('❌ Notifications FCM refusées');
        return;
      }
      
      // Récupérer FCM token
      final token = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $token');
      
      // TODO: Envoyer token au backend pour stocker dans DB
      // await _saveTokenToBackend(token);
      
      // Écouter les changements de token
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token rafraîchi: $newToken');
        // TODO: Envoyer nouveau token au backend
      });
      
      // Handler pour messages reçus en foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📬 Message en foreground: ${message.notification?.title}');
        _onMessageReceived?.call(message);
        _handleForegroundMessage(message);
      });
      
      // Handler pour app ouverte via notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📬 App ouverte via notification: ${message.notification?.title}');
        _onMessageOpenedApp?.call(message);
        _handleNotificationTap(message);
      });
      
      // Handler background (si app tuée)
      FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
      
      debugPrint('✅ FCM initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur initialisation FCM: $e');
    }
  }
  
  /// S'abonner à un topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Abonné au topic: $topic');
    } catch (e) {
      debugPrint('❌ Erreur abonnement topic: $e');
    }
  }
  
  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Désabonné du topic: $topic');
    } catch (e) {
      debugPrint('❌ Erreur désabonnement topic: $e');
    }
  }
  
  /// Récupérer le FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('❌ Erreur récupération FCM token: $e');
      return null;
    }
  }
  
  /// Enregistrer callback pour messages en foreground
  void setOnMessageCallback(Function(RemoteMessage) callback) {
    _onMessageReceived = callback;
  }
  
  /// Enregistrer callback pour ouverture notification
  void setOnMessageOpenedAppCallback(Function(RemoteMessage) callback) {
    _onMessageOpenedApp = callback;
  }
  
  /// Handler pour messages en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    final apple = message.notification?.apple;
    
    debugPrint('📨 Titre: ${notification?.title}');
    debugPrint('📨 Body: ${notification?.body}');
    
    // TODO: Afficher notification locale avec local_notifications package
    // ou toast
  }
  
  /// Handler pour tap sur notification
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    
    debugPrint('🔗 Data: $data');
    
    // TODO: Router vers page appropriée selon type de notification
    // - Exemple: if (data['type'] == 'chat') -> naviguer vers ChatScreen
    // - Exemple: if (data['type'] == 'order') -> naviguer vers OrderScreen
  }
  
  /// Handler background (app tuée)
  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    debugPrint('🔔 Background message: ${message.notification?.title}');
    // Traiter message même si app est tuée
    // Note: Fonctionnalité limitée en background
  }
}

