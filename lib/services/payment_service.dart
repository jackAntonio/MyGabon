import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';

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

/// Payment Service - Handles MyGabon Wallet and Airtel Money payments
class PaymentService {
  static const double VISIBLE_FEE_RATE = 0.05;  // 5% shown to user
  static const double ACTUAL_FEE_RATE = 0.10;   // 10% actually deducted
  static const double standardDeliveryFee = 5000; // FCFA, livraison MyGabon

  /// Calculate fees for a transaction
  static FeeCalculation calculateFees(double grossAmount) {
    final visibleFee = grossAmount * VISIBLE_FEE_RATE;
    final actualFee = grossAmount * ACTUAL_FEE_RATE;
    final netToSeller = grossAmount * (1 - ACTUAL_FEE_RATE);
    final totalWithVisibleFee = grossAmount + visibleFee;

    return FeeCalculation(
      visibleFee: visibleFee,
      actualFee: actualFee,
      netToSeller: netToSeller,
      totalWithVisibleFee: totalWithVisibleFee,
    );
  }

  /// Process MyGabon Wallet payment
  Future<Transaction> processMyGabonWallet({
    required String buyerId,
    required String sellerId,
    required String productId,
    required double amount,
    required double buyerWalletBalance,
  }) async {
    final fees = calculateFees(amount);

    // Check if buyer has sufficient balance
    if (buyerWalletBalance < fees.totalWithVisibleFee) {
      throw PaymentException('Solde insuffisant dans votre portefeuille MyGabon');
    }

    // Simulate API call to deduct from wallet and transfer to seller
    await Future.delayed(const Duration(seconds: 1));

    final transaction = Transaction(
      id: const Uuid().v4(),
      buyerId: buyerId,
      sellerId: sellerId,
      productId: productId,
      grossAmount: amount,
      visibleFee: fees.visibleFee,
      actualFee: fees.actualFee,
      netToSeller: fees.netToSeller,
      paymentMethod: PaymentMethod.myGabon,
      status: TransactionStatus.success,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      transactionReference: 'MYGABON_${const Uuid().v4().substring(0, 8).toUpperCase()}',
    );

    // Log transaction to backend
    await _logTransaction(transaction);

    return transaction;
  }

  /// Initiate Airtel Money payment
  Future<String> initiateAirtelMoneyPayment({
    required String buyerId,
    required String phoneNumber,
    required double amount,
  }) async {
    // Validate phone number format (Gabon: +241xxxxxxxxx or 06xxxxxxxx)
    if (!_isValidGabonPhoneNumber(phoneNumber)) {
      throw PaymentException('Numéro de téléphone invalide pour Gabon');
    }

    // Simulate API call to Airtel Money gateway
    await Future.delayed(const Duration(seconds: 1));

    // Return request ID for callback verification
    final requestId = 'AIRTEL_${const Uuid().v4()}';
    return requestId;
  }

  /// Confirm Airtel Money payment (after OTP confirmation)
  Future<Transaction> confirmAirtelMoneyPayment({
    required String buyerId,
    required String sellerId,
    required String productId,
    required double amount,
    required String airtelRequestId,
    required String otp,
  }) async {
    final fees = calculateFees(amount);

    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 1));

    // Simulate callback from Airtel Money confirming payment
    final transaction = Transaction(
      id: const Uuid().v4(),
      buyerId: buyerId,
      sellerId: sellerId,
      productId: productId,
      grossAmount: amount,
      visibleFee: fees.visibleFee,
      actualFee: fees.actualFee,
      netToSeller: fees.netToSeller,
      paymentMethod: PaymentMethod.airtelMoney,
      status: TransactionStatus.success,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      transactionReference: airtelRequestId,
    );

    // Log transaction to backend
    await _logTransaction(transaction);

    return transaction;
  }

  /// Cash payment tracking
  Future<Transaction> recordCashPayment({
    required String buyerId,
    required String sellerId,
    required String productId,
    required double amount,
  }) async {
    final fees = calculateFees(amount);

    final transaction = Transaction(
      id: const Uuid().v4(),
      buyerId: buyerId,
      sellerId: sellerId,
      productId: productId,
      grossAmount: amount,
      visibleFee: fees.visibleFee,
      actualFee: fees.actualFee,
      netToSeller: fees.netToSeller,
      paymentMethod: PaymentMethod.cash,
      status: TransactionStatus.pending,
      createdAt: DateTime.now(),
      notes: 'Paiement en espèces - À confirmer avec le vendeur',
    );

    // Log transaction to backend
    await _logTransaction(transaction);

    return transaction;
  }

  /// Log transaction to backend (Supabase)
  Future<void> _logTransaction(Transaction transaction) async {
    // TODO: Implement Supabase call
    // await supabase.from('transactions').insert(transaction.toJson());
  }

  /// Validate Gabon phone number
  bool _isValidGabonPhoneNumber(String phone) {
    // Accept formats: +241xxxxxxxxx or 06xxxxxxxx
    final gabonPattern = RegExp(r'^(\+241|06)\d{7,8}$');
    final cleanPhone = phone.replaceAll(' ', '').replaceAll('-', '');
    return gabonPattern.hasMatch(cleanPhone);
  }
}

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);

  @override
  String toString() => message;
}

// Riverpod providers
final paymentServiceProvider = Provider((ref) => PaymentService());

final transactionHistoryProvider = FutureProvider((ref) async {
  // TODO: Fetch from Supabase
  return <Transaction>[];
});
