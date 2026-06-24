import 'package:supabase_flutter/supabase_flutter.dart';

/// Client Kpay (Airtel Money Gabon) côté app.
///
/// ⚠️ Aucun secret Kpay ici : ni X-API-Key ni X-Secret-Key ne sont jamais
/// compilés dans l'app (règle du projet : "Jamais exposer les clés API
/// paiement dans le code Flutter"). L'appel réel à Kpay est fait par
/// l'Edge Function `kpay-initiate` (cf. supabase/functions/kpay-initiate),
/// qui détient les credentials côté serveur et vérifie via RLS que
/// l'appelant est bien l'acheteur de la transaction.
///
/// La doc officielle Kpay (https://kpay.site/documentation) ne décrit
/// aucune étape de confirmation par OTP : après l'initiation, l'utilisateur
/// valide directement la transaction sur son téléphone (USSD côté
/// opérateur). Le statut final n'arrive que via webhook serveur
/// (kpay-webhook -> Realtime, cf. SupabaseService.watchTransactionStatus) :
/// ce service ne fait qu'initier le paiement, jamais le confirmer.
class KpayService {
  static final KpayService _instance = KpayService._internal();

  factory KpayService() {
    return _instance;
  }

  KpayService._internal();

  /// Initier un paiement Airtel Money Gabon pour une transaction déjà
  /// créée côté Supabase (status='pending', payment_method='airtel_money').
  Future<KpayInitiateResponse> initiateAirtelMoneyPayment({
    required String transactionId,
    required String phoneNumber,
  }) async {
    try {
      final result = await Supabase.instance.client.functions.invoke(
        'kpay-initiate',
        body: {
          'transactionId': transactionId,
          'phoneNumber': _normalizePhoneNumber(phoneNumber),
        },
      );

      final data = result.data as Map<String, dynamic>;
      if (result.status == 200 && data['success'] == true) {
        return KpayInitiateResponse(
          success: true,
          paymentId: data['paymentId'] as String?,
          status: data['status'] as String? ?? 'PENDING',
        );
      }

      return KpayInitiateResponse(
        success: false,
        message: data['message'] as String? ?? 'Erreur initiation paiement',
      );
    } catch (e) {
      return KpayInitiateResponse(
        success: false,
        message: 'Erreur connexion: $e',
      );
    }
  }

  /// Normaliser le numéro de téléphone Gabon (Kpay attend le format
  /// international sans le '+', ex: 24106XXXXXXX).
  String _normalizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.startsWith('06') || cleaned.startsWith('07')) {
      return '241$cleaned';
    }
    if (cleaned.startsWith('241')) {
      return cleaned;
    }
    return '241$cleaned';
  }

  /// Valider le format du numéro Gabon
  bool isValidGabonPhone(String phone) {
    final normalized = _normalizePhoneNumber(phone);
    final gabonPattern = RegExp(r'^241\d{8}$');
    return gabonPattern.hasMatch(normalized);
  }

  /// Format prix pour affichage
  String formatPrice(double amount) {
    return '${amount.toStringAsFixed(0)} FCFA';
  }
}

/// Réponse d'initiation de paiement (via l'Edge Function kpay-initiate)
class KpayInitiateResponse {
  final bool success;
  final String? paymentId;
  final String? status;
  final String? message;

  KpayInitiateResponse({
    required this.success,
    this.paymentId,
    this.status,
    this.message,
  });
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
