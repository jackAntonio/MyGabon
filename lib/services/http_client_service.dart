import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';

/// HTTP Client qui rejette tout certificat invalide (fail-closed) plutôt que
/// d'accepter par défaut. Le certificate pinning réel (comparaison de hash
/// SHA256) reste un TODO tant que les domaines de production ne sont pas
/// figés — voir _createSecureHttpClient.
class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  
  late http.Client _client;
  
  factory HttpClientService() {
    return _instance;
  }
  
  HttpClientService._internal() {
    _client = _createSecureHttpClient();
  }
  
  /// Créer HTTP client sécurisé.
  /// Ce callback n'est invoqué que pour les certificats qui échouent déjà à
  /// la validation TLS standard (cert auto-signé, expiré, hostname invalide).
  /// Faute de pins SHA256 réels pour les domaines de production (Supabase,
  /// Kpay...), on rejette systématiquement plutôt que d'accepter par défaut :
  /// accepter un certificat invalide "en attendant" serait la faille, pas
  /// l'absence de pinning. Firebase n'est plus utilisé par ce projet
  /// (Supabase uniquement, cf. SUPABASE_VS_FIREBASE_DECISION.md), donc aucune
  /// exception n'est nécessaire pour ses domaines.
  static http.Client _createSecureHttpClient() {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback = (
          X509Certificate cert,
          String host,
          int port,
        ) {
          debugPrint('❌ Certificat invalide rejeté pour: $host:$port');
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
