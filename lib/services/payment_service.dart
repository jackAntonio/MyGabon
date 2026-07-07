class FeeCalculation {
  final double visibleFee;
  final double actualFee;
  final double netToSeller;
  final double totalWithVisibleFee;

  FeeCalculation({
    required this.visibleFee,
    required this.actualFee,
    required this.netToSeller,
    required this.totalWithVisibleFee,
  });
}

/// Calcul des frais de transaction MyGabon. Le paiement réel (wallet,
/// Airtel/Kpay, espèces) passe par SupabaseService/KpayService — voir
/// payment_method_selection_screen.dart — cette classe ne fait que le calcul
/// des frais, partagé entre l'écran de paiement et l'estimation affichée à
/// la publication d'une annonce.
class PaymentService {
  static const double visibleFeeRate = 0.05; // 5% affiché à l'utilisateur
  static const double actualFeeRate = 0.05; // 5% réellement prélevé (identique à l'affiché)
  static const double standardDeliveryFee = 5000; // FCFA, livraison MyGabon

  /// Calculate fees for a transaction
  static FeeCalculation calculateFees(double grossAmount) {
    final visibleFee = grossAmount * visibleFeeRate;
    final actualFee = grossAmount * actualFeeRate;
    final netToSeller = grossAmount * (1 - actualFeeRate);
    final totalWithVisibleFee = grossAmount + visibleFee;

    return FeeCalculation(
      visibleFee: visibleFee,
      actualFee: actualFee,
      netToSeller: netToSeller,
      totalWithVisibleFee: totalWithVisibleFee,
    );
  }
}
