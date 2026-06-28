import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_model.dart';
import '../providers/service_provider.dart';
import '../screens/chat_detail_screen.dart';
import 'modern_card.dart';
import 'verified_badge.dart';

/// Card widget displaying brief information about a service.
class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final distanceKm =
        context.watch<ServiceProvider>().distanceKmFor(service);

    return ModernCard(
      title: service.title,
      description: service.description,
      distanceLabel:
          distanceKm == null ? null : '${distanceKm.toStringAsFixed(1)} km',
      price: service.formattedPrice,
      rating: service.rating,
      sellerName: service.providerName,
      sellerAvatar: service.providerAvatar,
      badge: service.providerVerified ? const VerifiedSellerBadge() : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              otherUserId: service.providerId,
              otherUserName: service.providerName,
              otherUserAvatar: service.providerAvatar,
            ),
          ),
        );
      },
    );
  }
}
