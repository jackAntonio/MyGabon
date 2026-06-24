// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String?,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      sellerRating: (json['sellerRating'] as num).toDouble(),
      sellerVerified: json['sellerVerified'] as bool? ?? false,
      condition: json['condition'] as String,
      location: json['location'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      quantity: (json['quantity'] as num).toInt(),
      published: json['published'] as bool,
    );

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'category': instance.category,
      'imageUrl': instance.imageUrl,
      'sellerId': instance.sellerId,
      'sellerName': instance.sellerName,
      'sellerRating': instance.sellerRating,
      'sellerVerified': instance.sellerVerified,
      'condition': instance.condition,
      'location': instance.location,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'quantity': instance.quantity,
      'published': instance.published,
    };
