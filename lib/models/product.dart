import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String? category;
  final String? imageUrl;
  final String sellerId;
  final String sellerName;
  final double sellerRating;
  final bool sellerVerified;
  final String condition; // Neuf, Bon état, Occasion
  final String location; // City in Gabon
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int quantity;
  final bool published;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.category,
    this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.sellerRating,
    this.sellerVerified = false,
    required this.condition,
    required this.location,
    required this.createdAt,
    this.updatedAt,
    required this.quantity,
    required this.published,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  String get formattedPrice => '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))'), (Match m) => '${m.group(0)} ')} FCFA';
}
