import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/product.dart';
import '../providers/favorites_provider.dart';
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
    final isFavorite = context.watch<FavoritesProvider>().isFavorite(product.id);

    return Stack(
      children: [
        ModernCard(
          imageUrl: product.imageUrl,
          title: product.title,
          description: product.location,
          distanceLabel: distanceKm == null
              ? null
              : '${distanceKm.toStringAsFixed(1)} km',
          price: product.formattedPrice,
          rating: product.sellerRating,
          sellerName: product.sellerName,
          badge: product.sellerVerified ? const VerifiedSellerBadge() : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MarketplaceDetailScreen(product: product),
              ),
            );
          },
        ),
        Positioned(
          top: 8,
          left: 8,
          child: GestureDetector(
            onTap: () => context.read<FavoritesProvider>().toggle(product),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 18,
                color: isFavorite ? AppColors.error : AppColors.grey600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
