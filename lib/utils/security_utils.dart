import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Security utilities for encryption and data protection
/// ℹ️ Le hachage des mots de passe est géré par Supabase Auth côté serveur
/// (jamais par le client) — pas de hashPassword/verifyPassword ici.
/// ✅ SÉCURISÉ: OTP générés avec Random.secure()
class SecurityUtils {
  /// Masquer un numéro de téléphone pour affichage.
  /// ⚠️ Masquage irréversible (pas du chiffrement) : ne permet pas de
  /// retrouver la valeur d'origine.
  static String maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 4) return '****';
    return '*' * (phoneNumber.length - 4) +
        phoneNumber.substring(phoneNumber.length - 4);
  }

  /// Masquer un numéro d'ID pour affichage.
  /// ⚠️ Masquage irréversible (pas du chiffrement) : ne permet pas de
  /// retrouver la valeur d'origine.
  static String maskIdNumber(String idNumber) {
    if (idNumber.length < 4) return '****';
    return 'ID_${'*' * 6}${idNumber.substring(idNumber.length - 3)}';
  }

  /// Générer un OTP sécurisé avec Random.secure() (✅ SÉCURISÉ)
  /// Utilise cryptographiquement sécurisé générateur de nombres aléatoires
  static String generateOTP({int length = 6}) {
    try {
      final random = Random.secure();
      final values = List<int>.generate(length, (i) => random.nextInt(10));
      return values.join();
    } catch (e) {
      debugPrint('❌ Erreur génération OTP: $e');
      rethrow;
    }
  }

  static bool isValidOTP(String otp) {
    return otp.length == 6 && int.tryParse(otp) != null;
  }

  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].length < 2) return '****@${parts[1]}';
    return '${parts[0][0]}${'*' * (parts[0].length - 2)}${parts[0][parts[0].length - 1]}@${parts[1]}';
  }
}

/// Input validation utilities.
/// ⚠️ La protection contre l'injection SQL vient des requêtes paramétrées du
/// client Supabase, pas d'une liste noire de mots-clés ici (une telle liste
/// donne un faux sentiment de sécurité et génère des faux positifs sur du
/// texte légitime).
class SecurityValidator {
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  static bool isValidPhoneNumber(String phone) {
    // Gabon country code +241 or local format
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.length >= 9 && cleaned.length <= 13;
  }

  static bool isValidIdFormat(String id) {
    // Basic ID validation (adjustable per country)
    return id.isNotEmpty && id.length >= 5 && id.length <= 20;
  }

  static bool isSuspiciousActivity(String activity) {
    // Detect common fraud patterns
    final suspiciousKeywords = [
      'bank account',
      'wire transfer',
      'western union',
      'bitcoin',
      'crypto',
      'gift card',
      'urgent',
      'limited time',
      'act now',
      'guaranteed profit',
      'free money'
    ];

    final lowerActivity = activity.toLowerCase();
    return suspiciousKeywords.any((keyword) => lowerActivity.contains(keyword));
  }
}

/// Rate limiting for API calls
class RateLimiter {
  final Map<String, List<DateTime>> _requestHistory = {};
  final int _maxRequests;
  final Duration _timeWindow;

  RateLimiter({int maxRequests = 10, Duration? timeWindow})
      : _maxRequests = maxRequests,
        _timeWindow = timeWindow ?? const Duration(minutes: 1);

  bool isAllowed(String userId) {
    final now = DateTime.now();

    if (!_requestHistory.containsKey(userId)) {
      _requestHistory[userId] = [];
    }

    // Clean old requests
    _requestHistory[userId]!
        .removeWhere((time) => now.difference(time) > _timeWindow);

    // Check rate limit
    if (_requestHistory[userId]!.length >= _maxRequests) {
      return false;
    }

    _requestHistory[userId]!.add(now);
    return true;
  }

  int getRemainingRequests(String userId) {
    final now = DateTime.now();

    if (!_requestHistory.containsKey(userId)) {
      return _maxRequests;
    }

    // Clean old requests
    _requestHistory[userId]!
        .removeWhere((time) => now.difference(time) > _timeWindow);

    return (_maxRequests - _requestHistory[userId]!.length)
        .clamp(0, _maxRequests);
  }
}

/// Device fingerprinting for fraud detection
class DeviceFingerprint {
  final String deviceId;
  final String deviceModel;
  final String osVersion;
  final String appVersion;
  final DateTime createdAt;

  DeviceFingerprint({
    required this.deviceId,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String getFingerprint() {
    final data = '$deviceId:$deviceModel:$osVersion:$appVersion';
    return sha256.convert(utf8.encode(data)).toString();
  }
}
