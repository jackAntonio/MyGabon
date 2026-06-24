import 'package:flutter/foundation.dart';
import 'package:pay/pay.dart';
import '../models/product.dart';

/// Configuration de test (gateway "example" = sandbox officiel Google Pay).
/// ⚠️ À remplacer avant production : merchantIdentifier (Apple) et
/// gatewayMerchantId (Google) réels, une fois les comptes marchands créés
/// (cf. APPLE_PAY_SETUP.md). Sans ça, userCanPay() peut renvoyer true mais
/// la transaction réelle échouera côté Apple/Google.
const _applePayConfigJson = '''
{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "merchant.com.mygabon.app",
    "displayName": "MyGabon",
    "merchantCapabilities": ["3DS"],
    "supportedNetworks": ["visa", "masterCard", "amex"],
    "countryCode": "GA",
    "currencyCode": "XAF"
  }
}
''';

const _googlePayConfigJson = '''
{
  "provider": "google_pay",
  "data": {
    "environment": "TEST",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "example",
            "gatewayMerchantId": "mygabon-test-merchant"
          }
        },
        "parameters": {
          "allowedCardNetworks": ["VISA", "MASTERCARD"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": false
        }
      }
    ],
    "merchantInfo": {
      "merchantName": "MyGabon"
    },
    "transactionInfo": {
      "countryCode": "GA",
      "currencyCode": "XAF"
    }
  }
}
''';

/// Service Apple Pay & Google Pay (via le plugin `pay`).
/// Devises XAF/Gabon ne sont pas universellement supportées par tous les
/// réseaux de cartes ; à valider en conditions réelles une fois le compte
/// marchand configuré.
class ApplePayService {
  static final ApplePayService _instance = ApplePayService._internal();

  late final Pay _payClient;
  bool _initialized = false;

  factory ApplePayService() {
    return _instance;
  }

  ApplePayService._internal() {
    _payClient = Pay({
      PayProvider.apple_pay:
          PaymentConfiguration.fromJsonString(_applePayConfigJson),
      PayProvider.google_pay:
          PaymentConfiguration.fromJsonString(_googlePayConfigJson),
    });
  }

  /// Initialiser Apple Pay
  Future<void> init() async {
    try {
      final canPay = await _payClient.userCanPay(PayProvider.apple_pay);
      _initialized = canPay;
      debugPrint(canPay
          ? '✅ Apple Pay disponible'
          : '⚠️ Apple Pay non disponible sur ce device');
    } catch (e) {
      debugPrint('❌ Erreur initialisation Apple Pay: $e');
    }
  }

  /// Vérifier si Apple Pay est disponible
  Future<bool> isAvailable() async {
    try {
      return await _payClient.userCanPay(PayProvider.apple_pay);
    } catch (e) {
      return false;
    }
  }

  /// Vérifier si Google Pay est disponible
  Future<bool> isGooglePayAvailable() async {
    try {
      return await _payClient.userCanPay(PayProvider.google_pay);
    } catch (e) {
      return false;
    }
  }

  List<PaymentItem> _buildPaymentItems({
    required Product product,
    required double totalAmount,
  }) {
    return [
      PaymentItem(
        label: product.title,
        amount: totalAmount.toStringAsFixed(2),
        status: PaymentItemStatus.final_price,
      ),
    ];
  }

  /// Traiter paiement Apple Pay
  Future<bool> processPayment({
    required Product product,
    required double totalAmount,
    required double visibleFee,
    required String countryCode,
  }) async {
    if (!_initialized) {
      debugPrint('⚠️ Apple Pay non initialisé');
      return false;
    }
    try {
      await _payClient.showPaymentSelector(
        PayProvider.apple_pay,
        _buildPaymentItems(product: product, totalAmount: totalAmount),
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
      final userCanPay = await _payClient.userCanPay(PayProvider.google_pay);
      if (!userCanPay) {
        debugPrint('⚠️ Google Pay non disponible');
        return false;
      }

      await _payClient.showPaymentSelector(
        PayProvider.google_pay,
        _buildPaymentItems(product: product, totalAmount: totalAmount),
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
