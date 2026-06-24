import 'package:flutter/material.dart';
import '../models/product.dart';
import '../screens/marketplace_detail_screen.dart';
import 'modern_card.dart';
import 'verified_badge.dart';

/// Card used for marketplace products.
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      imageUrl: product.imageUrl,
      title: product.title,
      description: product.location,
      price: product.formattedPrice,
      rating: product.sellerRating,
      sellerName: product.sellerName,
      badge: product.sellerVerified ? const VerifiedSellerBadge() : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarketplaceDetailScreen(product: product),
          ),
        );
      },
    );
  }
}
