import 'package:flutter/foundation.dart';
import 'package:pay/pay.dart';
import '../models/product.dart';

/// Service Apple Pay & Google Pay
class ApplePayService {
  static final ApplePayService _instance = ApplePayService._internal();

  late final Pay _payClient;
  bool _initialized = false;

  factory ApplePayService() {
    return _instance;
  }

  ApplePayService._internal() {
    _payClient = Pay();
  }

  /// Initialiser Apple Pay
  Future<void> init() async {
    try {
      // Vérifier disponibilité
      final userCanPay = await _payClient.userCanPay(
        provider: PaymentProvider.apple_pay,
      );

      if (userCanPay) {
        _initialized = true;
        debugPrint('✅ Apple Pay disponible');
      } else {
        debugPrint('⚠️ Apple Pay non disponible sur ce device');
      }
    } catch (e) {
      debugPrint('❌ Erreur initialisation Apple Pay: $e');
    }
  }

  /// Vérifier si Apple Pay est disponible
  Future<bool> isAvailable() async {
    try {
      return await _payClient.userCanPay(
        provider: PaymentProvider.apple_pay,
      );
    } catch (e) {
      return false;
    }
  }

  /// Traiter paiement Apple Pay
  Future<bool> processPayment({
    required Product product,
    required double totalAmount,
    required double visibleFee,
    required String countryCode,
  }) async {
    try {
      if (!_initialized) {
        debugPrint('⚠️ Apple Pay non initialisé');
        return false;
      }

      final paymentItems = [
        PaymentItem(
          label: product.title,
          amount: (product.price / 100).toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
        PaymentItem(
          label: 'Frais de plateforme',
          amount: (visibleFee / 100).toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
        PaymentItem(
          label: 'Montant total',
          amount: (totalAmount / 100).toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
      ];

      await _payClient.showPaymentSelector(
        provider: PaymentProvider.apple_pay,
        paymentItems: paymentItems,
      );

      debugPrint('✅ Paiement Apple Pay réussi');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur Apple Pay: $e');
      return false;
    }
  }

  /// Traiter paiement Google Pay (même service)
  Future<bool> processGooglePayment({
    required Product product,
    required double totalAmount,
    required double visibleFee,
  }) async {
    try {
      final userCanPay = await _payClient.userCanPay(
        provider: PaymentProvider.google_pay,
      );

      if (!userCanPay) {
        debugPrint('⚠️ Google Pay non disponible');
        return false;
      }

      final paymentItems = [
        PaymentItem(
          label: product.title,
          amount: (product.price / 100).toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
        PaymentItem(
          label: 'Frais de plateforme',
          amount: (visibleFee / 100).toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
        PaymentItem(
          label: 'Montant total',
          amount: (totalAmount / 100).toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
      ];

      await _payClient.showPaymentSelector(
        provider: PaymentProvider.google_pay,
        paymentItems: paymentItems,
      );

      debugPrint('✅ Paiement Google Pay réussi');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur Google Pay: $e');
      return false;
    }
  }
}

final applePayService = ApplePayService();
