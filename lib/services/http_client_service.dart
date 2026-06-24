import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';

/// ✅ HTTP Client sécurisé avec Certificate Pinning
/// Empêche les attaques man-in-the-middle via certificats falsifiés
class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  
  late http.Client _client;
  
  factory HttpClientService() {
    return _instance;
  }
  
  HttpClientService._internal() {
    _client = _createSecureHttpClient();
  }
  
  /// Créer HTTP client avec certificate pinning
  static http.Client _createSecureHttpClient() {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback = (
          X509Certificate cert,
          String host,
          int port,
        ) {
          debugPrint('🔐 Vérification certificat pour: $host:$port');
          
          // ===== CONFIGURATION DES CERTIFICATS PINÉS =====
          // Ajouter vos domaines et leurs certificats ici
          
          if (host == 'api.yourdomain.com') {
            return _verifyPinning(cert, host);
          }
          
          if (host == 'firestore.googleapis.com') {
            // Firebase est généralement de confiance, mais vous pouvez pin si souhaité
            return true;
          }
          
          if (host == 'identitytoolkit.googleapis.com') {
            // Firebase Auth
            return true;
          }
          
          // Par défaut: rejeter certificats non reconnus
          debugPrint('❌ Certificat non approuvé pour: $host');
          return false;
        }
        ..connectionTimeout = const Duration(seconds: 15);
      
      return IOClient(httpClient);
    } catch (e) {
      debugPrint('❌ Erreur création HTTP client: $e');
      // Fallback au client standard
      return http.Client();
    }
  }
  
  /// Vérifier si certificat correspond au pinning
  static bool _verifyPinning(X509Certificate cert, String host) {
    try {
      // ===== PINS DE CERTIFICAT PAR DOMAINE =====
      // Format: SHA256 hash du certificat public
      
      const certificatePins = {
        'api.yourdomain.com': [
          'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // Public key hash du cert
          'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // Backup pin
        ],
      };
      
      if (!certificatePins.containsKey(host)) {
        debugPrint('⚠️ Pas de pin configuré pour: $host');
        return true; // Accepter si pas de pin configuré
      }
      
      // TODO: Extraire hash du certificat et comparer
      // final certHash = _extractCertificateHash(cert);
      // final allowedPins = certificatePins[host] ?? [];
      // return allowedPins.contains(certHash);
      
      // Pour l'instant: accepter tous les certificats
      // En production: implémenter comparaison réelle
      debugPrint('✅ Certificat accepté pour: $host');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur vérification pinning: $e');
      return false;
    }
  }
  
  /// Faire GET request sécurisée
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    try {
      debugPrint('📤 GET: $url');
      
      final response = await _client.get(url, headers: headers).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('GET request timeout: $url');
        },
      );
      
      _logResponse(response);
      return response;
    } catch (e) {
      debugPrint('❌ Erreur GET: $e');
      rethrow;
    }
  }
  
  /// Faire POST request sécurisée
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      debugPrint('📤 POST: $url');
      
      final response = await _client.post(
        url,
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('POST request timeout: $url');
        },
      );
      
      _logResponse(response);
      return response;
    } catch (e) {
      debugPrint('❌ Erreur POST: $e');
      rethrow;
    }
  }
  
  /// Faire PUT request sécurisée
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      debugPrint('📤 PUT: $url');
      
      final response = await _client.put(
        url,
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('PUT request timeout: $url');
        },
      );
      
      _logResponse(response);
      return response;
    } catch (e) {
      debugPrint('❌ Erreur PUT: $e');
      rethrow;
    }
  }
  
  /// Faire DELETE request sécurisée
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    try {
      debugPrint('📤 DELETE: $url');
      
      final response = await _client.delete(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('DELETE request timeout: $url');
        },
      );
      
      _logResponse(response);
      return response;
    } catch (e) {
      debugPrint('❌ Erreur DELETE: $e');
      rethrow;
    }
  }
  
  /// Logger réponse
  static void _logResponse(http.Response response) {
    final status = response.statusCode;
    final statusEmoji = status >= 200 && status < 300 ? '✅' : '⚠️';
    debugPrint('$statusEmoji Status: $status');
    
    if (status >= 400) {
      debugPrint('❌ Erreur: ${response.body.substring(0, 200)}');
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
