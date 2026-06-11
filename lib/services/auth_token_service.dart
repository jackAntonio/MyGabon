import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/foundation.dart';

/// ✅ Service pour générer et vérifier JWT tokens
/// Access token: Courte durée (15 min) pour API calls
/// Refresh token: Longue durée (7 jours) pour renouveller access token
class AuthTokenService {
  static const Duration _accessTokenExpiry = Duration(minutes: 15);
  static const Duration _refreshTokenExpiry = Duration(days: 7);
  
  late final String _jwtSecret;
  
  AuthTokenService({required String jwtSecret}) {
    _jwtSecret = jwtSecret;
    if (_jwtSecret.length < 32) {
      throw Exception('JWT secret doit avoir minimum 32 caractères');
    }
  }
  
  /// Générer un access token (court)
  /// Utilisé pour authentifier les requêtes API
  String generateAccessToken({
    required String userId,
    required String email,
  }) {
    try {
      final jwt = JWT({
        'userId': userId,
        'email': email,
        'iat': DateTime.now().millisecondsSinceEpoch,
        'exp': DateTime.now().add(_accessTokenExpiry).millisecondsSinceEpoch,
        'type': 'access',
      });
      
      final token = jwt.sign(SecretKey(_jwtSecret));
      debugPrint('✅ Access token généré pour: $userId');
      return token;
    } catch (e) {
      debugPrint('❌ Erreur génération access token: $e');
      rethrow;
    }
  }
  
  /// Générer un refresh token (long)
  /// Utilisé pour obtenir un nouvel access token
  String generateRefreshToken({
    required String userId,
  }) {
    try {
      final jwt = JWT({
        'userId': userId,
        'iat': DateTime.now().millisecondsSinceEpoch,
        'exp': DateTime.now().add(_refreshTokenExpiry).millisecondsSinceEpoch,
        'type': 'refresh',
      });
      
      final token = jwt.sign(SecretKey(_jwtSecret));
      debugPrint('✅ Refresh token généré pour: $userId');
      return token;
    } catch (e) {
      debugPrint('❌ Erreur génération refresh token: $e');
      rethrow;
    }
  }
  
  /// Vérifier si un token est valide
  bool verifyToken(String token) {
    try {
      JWT.verify(token, SecretKey(_jwtSecret));
      return true;
    } on JWTExpiredException {
      debugPrint('⏰ Token expiré');
      return false;
    } on JWTException catch (e) {
      debugPrint('❌ Token invalide: $e');
      return false;
    }
  }
  
  /// Extraire userId d'un token valide
  String? getUserIdFromToken(String token) {
    try {
      if (!verifyToken(token)) return null;
      
      final decoded = JWT.decode(token);
      return decoded.payload['userId'] as String?;
    } catch (e) {
      debugPrint('❌ Erreur extraction userId: $e');
      return null;
    }
  }
  
  /// Extraire type de token (access ou refresh)
  String? getTokenType(String token) {
    try {
      if (!verifyToken(token)) return null;
      
      final decoded = JWT.decode(token);
      return decoded.payload['type'] as String?;
    } catch (e) {
      return null;
    }
  }
  
  /// Vérifier si token expire bientôt (dans les 1 min)
  bool isTokenExpiringSoon(String token) {
    try {
      final decoded = JWT.decode(token);
      final expMs = decoded.payload['exp'] as int?;
      if (expMs == null) return true;
      
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(expMs);
      final now = DateTime.now();
      final timeLeft = expiryTime.difference(now);
      
      return timeLeft.inMinutes < 1;
    } catch (e) {
      return true;
    }
  }
}
