import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

/// Service Kpay pour paiements Airtel Money et autres méthodes
class KpayService {
  static final KpayService _instance = KpayService._internal();
  static const String _kpayBaseUrl = 'https://api.kpay.africa/api/v1';

  late final Dio _dio;
  String? _apiKey;
  String? _merchantId;
  String? _webhookSecret;

  factory KpayService() {
    return _instance;
  }

  KpayService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _kpayBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // Intercepteur pour les logs
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('🔄 Kpay Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ Kpay Response: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ Kpay Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  /// Initialiser Kpay avec les credentials
  void init({
    required String apiKey,
    required String merchantId,
    String? webhookSecret,
  }) {
    _apiKey = apiKey;
    _merchantId = merchantId;
    _webhookSecret = webhookSecret;
    debugPrint('✅ Kpay initialisé avec merchant: $merchantId');
  }

  // ========== AIRTEL MONEY ==========

  /// Initier un paiement Airtel Money
  Future<KpayPaymentResponse> initiateAirtelPayment({
    required String phoneNumber,
    required double amount,
    required String productName,
    required String productId,
    String? externalId,
  }) async {
    try {
      if (_apiKey == null || _merchantId == null) {
        throw KpayException('Kpay non initialisé');
      }

      final transactionId = externalId ?? const Uuid().v4();

      final payload = {
        'merchant_id': _merchantId,
        'api_key': _apiKey,
        'phone_number': _normalizePhoneNumber(phoneNumber),
        'amount': amount,
        'currency': 'XAF', // Franc CFA
        'description': productName,
        'reference': transactionId,
        'payment_method': 'airtel',
        'callback_url': 'https://mygabon.app/api/payment/callback',
        'return_url': 'mygabon://payment-success',
        'notification_language': 'fr',
      };

      debugPrint('📤 Initiating Airtel payment: $transactionId');

      final response = await _dio.post(
        '/payments/initiate',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': _apiKey,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return KpayPaymentResponse(
          success: data['success'] ?? true,
          transactionId: data['transaction_id'] ?? transactionId,
          requestId: data['request_id'],
          status: data['status'] ?? 'pending',
          message: data['message'] ?? 'Paiement initié',
          phoneNumber: phoneNumber,
          amount: amount,
          reference: transactionId,
        );
      }

      throw KpayException(
        'Erreur initiation paiement: ${response.statusCode}',
      );
    } on DioException catch (e) {
      debugPrint('❌ Erreur Dio: ${e.message}');
      throw KpayException('Erreur connexion Kpay: ${e.message}');
    } catch (e) {
      debugPrint('❌ Erreur: $e');
      rethrow;
    }
  }

  /// Vérifier le statut d'un paiement
  Future<KpayPaymentStatus> checkPaymentStatus({
    required String transactionId,
  }) async {
    try {
      if (_apiKey == null) {
        throw KpayException('Kpay non initialisé');
      }

      final response = await _dio.get(
        '/payments/status/$transactionId',
        options: Options(
          headers: {
            'X-API-Key': _apiKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return KpayPaymentStatus(
          transactionId: data['transaction_id'],
          status: data['status'] ?? 'unknown',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          phoneNumber: data['phone_number'],
          message: data['message'],
          paidAt: data['paid_at'] != null
              ? DateTime.parse(data['paid_at'])
              : null,
        );
      }

      throw KpayException('Erreur vérification statut: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Erreur statut: $e');
      rethrow;
    }
  }

  /// Confirmer un paiement Airtel (après OTP)
  Future<KpayConfirmResponse> confirmAirtelPayment({
    required String transactionId,
    required String otp,
  }) async {
    try {
      if (_apiKey == null) {
        throw KpayException('Kpay non initialisé');
      }

      final payload = {
        'transaction_id': transactionId,
        'otp': otp,
        'api_key': _apiKey,
      };

      debugPrint('✔️ Confirming payment: $transactionId');

      final response = await _dio.post(
        '/payments/confirm',
        data: payload,
        options: Options(
          headers: {
            'X-API-Key': _apiKey,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return KpayConfirmResponse(
          success: data['success'] ?? true,
          transactionId: data['transaction_id'] ?? transactionId,
          status: data['status'] ?? 'completed',
          message: data['message'] ?? 'Paiement confirmé',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
        );
      }

      throw KpayException(
        'Erreur confirmation: ${response.statusCode} - ${response.data['message']}',
      );
    } on DioException catch (e) {
      debugPrint('❌ Erreur Dio confirmation: ${e.message}');
      throw KpayException('Erreur confirmation: ${e.message}');
    } catch (e) {
      debugPrint('❌ Erreur confirmation: $e');
      rethrow;
    }
  }

  // ========== UTILITAIRES ==========

  /// Normaliser le numéro de téléphone Gabon
  /// Accepte: +241XXXXXXXX, 06XXXXXXXX, 237XXXXXXXX
  String _normalizePhoneNumber(String phone) {
    // Enlever les espaces et caractères spéciaux
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Si commence par +, retourner tel quel
    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    // Si commence par 06, ajouter +241
    if (cleaned.startsWith('06')) {
      return '+241${cleaned.substring(2)}';
    }

    // Si commence par 06 ou 237, ajouter +
    if (cleaned.startsWith('237')) {
      return '+$cleaned';
    }

    // Par défaut, ajouter +241
    return '+241$cleaned';
  }

  /// Valider le format du numéro Gabon
  bool isValidGabonPhone(String phone) {
    String normalized = _normalizePhoneNumber(phone);
    final gabonPattern = RegExp(r'^\+241\d{8}$');
    return gabonPattern.hasMatch(normalized);
  }

  /// Vérifier le webhook signature
  bool verifyWebhookSignature(String payload, String signature) {
    if (_webhookSecret == null) return false;

    final bytes = utf8.encode('$payload$_webhookSecret');
    final computed = base64.encode(bytes);

    return computed == signature;
  }

  /// Format prix pour affichage
  String formatPrice(double amount) {
    return '${amount.toStringAsFixed(0)} FCFA';
  }

  /// Générer un hash pour les transactions
  String generateTransactionHash(String data) {
    return base64.encode(utf8.encode(data));
  }
}

// ========== MODELS ==========

/// Réponse d'initiation de paiement Kpay
class KpayPaymentResponse {
  final bool success;
  final String transactionId;
  final String? requestId;
  final String status; // pending, processing, completed, failed
  final String message;
  final String phoneNumber;
  final double amount;
  final String reference;

  KpayPaymentResponse({
    required this.success,
    required this.transactionId,
    this.requestId,
    required this.status,
    required this.message,
    required this.phoneNumber,
    required this.amount,
    required this.reference,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'transaction_id': transactionId,
    'request_id': requestId,
    'status': status,
    'message': message,
    'phone_number': phoneNumber,
    'amount': amount,
    'reference': reference,
  };
}

/// Statut d'un paiement
class KpayPaymentStatus {
  final String transactionId;
  final String status;
  final double amount;
  final String? phoneNumber;
  final String? message;
  final DateTime? paidAt;

  KpayPaymentStatus({
    required this.transactionId,
    required this.status,
    required this.amount,
    this.phoneNumber,
    this.message,
    this.paidAt,
  });

  bool get isCompleted => status == 'completed' || status == 'success';
  bool get isPending => status == 'pending' || status == 'processing';
  bool get isFailed => status == 'failed' || status == 'error';
}

/// Réponse de confirmation de paiement
class KpayConfirmResponse {
  final bool success;
  final String transactionId;
  final String status;
  final String message;
  final double amount;

  KpayConfirmResponse({
    required this.success,
    required this.transactionId,
    required this.status,
    required this.message,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'transaction_id': transactionId,
    'status': status,
    'message': message,
    'amount': amount,
  };
}

/// Exception Kpay
class KpayException implements Exception {
  final String message;
  KpayException(this.message);

  @override
  String toString() => message;
}

/// Instance globale
final kpayService = KpayService();
