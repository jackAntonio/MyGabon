// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      id: json['id'] as String,
      buyerId: json['buyerId'] as String,
      sellerId: json['sellerId'] as String,
      productId: json['productId'] as String,
      grossAmount: (json['grossAmount'] as num).toDouble(),
      visibleFee: (json['visibleFee'] as num).toDouble(),
      actualFee: (json['actualFee'] as num).toDouble(),
      netToSeller: (json['netToSeller'] as num).toDouble(),
      paymentMethod: $enumDecode(_$PaymentMethodEnumMap, json['paymentMethod']),
      status: $enumDecode(_$TransactionStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      transactionReference: json['transactionReference'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'buyerId': instance.buyerId,
      'sellerId': instance.sellerId,
      'productId': instance.productId,
      'grossAmount': instance.grossAmount,
      'visibleFee': instance.visibleFee,
      'actualFee': instance.actualFee,
      'netToSeller': instance.netToSeller,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod]!,
      'status': _$TransactionStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'transactionReference': instance.transactionReference,
      'notes': instance.notes,
    };

const _$PaymentMethodEnumMap = {
  PaymentMethod.myGabon: 'myGabon',
  PaymentMethod.airtelMoney: 'airtelMoney',
  PaymentMethod.cash: 'cash',
};

const _$TransactionStatusEnumMap = {
  TransactionStatus.pending: 'pending',
  TransactionStatus.success: 'success',
  TransactionStatus.failed: 'failed',
  TransactionStatus.cancelled: 'cancelled',
};
