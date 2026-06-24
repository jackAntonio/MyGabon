import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Badge compact "Vérifié" pour les vendeurs/prestataires dont le compte
/// est confirmé (champ `verified` sur `users`).
class VerifiedSellerBadge extends StatelessWidget {
  final double size;

  const VerifiedSellerBadge({Key? key, this.size = 12}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: AppColors.white, size: size),
          const SizedBox(width: 4),
          Text(
            'Vérifié',
            style: TextStyle(
              color: AppColors.white,
              fontSize: size - 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
