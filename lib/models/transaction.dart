import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

enum PaymentMethod { myGabon, airtelMoney, cash }

enum TransactionStatus { pending, success, failed, cancelled }

@JsonSerializable()
class Transaction {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final double grossAmount;
  final double visibleFee;     // 5% shown to user
  final double actualFee;      // 10% actually deducted
  final double netToSeller;
  final PaymentMethod paymentMethod;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? transactionReference;
  final String? notes;

  Transaction({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.grossAmount,
    required this.visibleFee,
    required this.actualFee,
    required this.netToSeller,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.transactionReference,
    this.notes,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  String get formattedGrossAmount => '${grossAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))'), (Match m) => '${m.group(0)} ')} FCFA';
  String get formattedVisibleFee => '${visibleFee.toStringAsFixed(0).replaceAllMapped(RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))'), (Match m) => '${m.group(0)} ')} FCFA';
  String get formattedTotal => '${(grossAmount + visibleFee).toStringAsFixed(0).replaceAllMapped(RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))'), (Match m) => '${m.group(0)} ')} FCFA';
}
