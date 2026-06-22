import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/product.dart';

/// Payment success screen with animated checkmark
class PaymentSuccessScreen extends StatefulWidget {
  final Product product;
  final double totalAmount;
  final String transactionId;

  const PaymentSuccessScreen({
    Key? key,
    required this.product,
    required this.totalAmount,
    required this.transactionId,
  }) : super(key: key);

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Animated checkmark
                  _buildAnimatedCheckmark(),

                  const SizedBox(height: 40),

                  // Success message
                  Text(
                    'Paiement réussi!',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Votre commande a été confirmée',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.grey600,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Transaction details
                  _buildTransactionDetails(context),

                  const SizedBox(height: 40),

                  // Product info
                  _buildProductInfo(context),

                  const SizedBox(height: 40),

                  // Info box
                  _buildInfoBox(context),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(context),
      ),
    );
  }

  Widget _buildAnimatedCheckmark() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(60),
      ),
      child: const Icon(
        Icons.check_circle_rounded,
        size: 80,
        color: AppColors.success,
      ),
    )
        .animate()
        .scale(
          duration: 600.ms,
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
        )
        .then()
        .scaleXY(begin: 1, end: 1.1, duration: 400.ms)
        .then()
        .scaleXY(begin: 1.1, end: 1, duration: 200.ms);
  }

  Widget _buildTransactionDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            context,
            label: 'Montant payé',
            value: _formatPrice(widget.totalAmount),
            isHighlight: true,
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.grey300),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            label: 'N° de transaction',
            value: '${widget.transactionId.substring(0, 20)}...',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            label: 'Date & Heure',
            value: _formatDateTime(DateTime.now()),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey600,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight ? AppColors.primary : AppColors.grey900,
              ),
        ),
      ],
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.accent.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: widget.product.imageUrl != null
                ? Image.network(
                    widget.product.imageUrl!,
                    fit: BoxFit.cover,
                  )
                : const Icon(
                    Icons.image_outlined,
                    color: AppColors.grey400,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produit commandé',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prochaines étapes',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Vous recevrez un SMS de confirmation\n• Le vendeur sera notifié\n• Livraison MyGabon dans 2-3 jours',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.info,
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.grey200),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              // Navigate back to home
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Retour à l\'accueil',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.white,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              // Open order tracking
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: Text(
              'Suivre ma commande',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    String result = '';
    int count = 0;
    for (int i = parts.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result = ' $result';
      }
      result = '${parts[i]}$result';
      count++;
    }
    return '$result FCFA';
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year à $hour:$minute';
  }
}
