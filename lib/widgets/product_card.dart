import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/marketplace_provider.dart';
import '../screens/marketplace_detail_screen.dart';
import 'modern_card.dart';
import 'verified_badge.dart';

/// Card used for marketplace products.
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final distanceKm =
        context.watch<MarketplaceProvider>().distanceKmFor(product);

    return ModernCard(
      imageUrl: product.imageUrl,
      title: product.title,
      description: product.location,
      distanceLabel:
          distanceKm == null ? null : '${distanceKm.toStringAsFixed(1)} km',
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
