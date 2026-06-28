import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../screens/chat_detail_screen.dart';
import 'modern_card.dart';
import 'verified_badge.dart';

/// Card widget displaying brief information about a service.
class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      title: service.title,
      description: service.description,
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
