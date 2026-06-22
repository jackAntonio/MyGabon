import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/product.dart';

class PaymentSuccessScreenComplete extends StatelessWidget {
  final Product product;
  final double totalAmount;
  final String transactionId;

  const PaymentSuccessScreenComplete({
    Key? key,
    required this.product,
    required this.totalAmount,
    required this.transactionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Animated checkmark
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 60,
                      color: AppColors.success,
                    ),
                  )
                      .animate()
                      .scaleXY(
                          begin: 0,
                          end: 1,
                          duration: const Duration(milliseconds: 600))
                      .then()
                      .shake(
                          hz: 2, duration: const Duration(milliseconds: 300)),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Paiement réussi!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Votre commande a été confirmée',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.grey600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Transaction details card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Column(
                      children: [
                        // Product info
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
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
                              child: const Icon(Icons.shopping_bag,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.title,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Vendeur: ${product.sellerName}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.grey600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.grey300),
                        const SizedBox(height: 20),

                        // Transaction info
                        _buildInfoRow(
                          context,
                          label: 'Montant',
                          value: '${totalAmount.toStringAsFixed(0)} FCFA',
                          isHighlight: true,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          label: 'ID Transaction',
                          value: transactionId,
                          isCopyable: true,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          label: 'Date',
                          value: _formatDate(DateTime.now()),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          label: 'Statut',
                          value: 'Confirmé',
                          valueColor: AppColors.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Next steps
                  _buildNextSteps(context),
                  const SizedBox(height: 40),

                  // Action buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.primary,
                          ),
                          child: Text(
                            'Retourner à la marketplace',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppColors.white,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reçu téléchargé'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          child: Text(
                            'Télécharger le reçu',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppColors.primary,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isHighlight = false,
    bool isCopyable = false,
    Color? valueColor,
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
        GestureDetector(
          onTap: isCopyable
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copié!')),
                  );
                }
              : null,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                  color: valueColor,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextSteps(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prochaines étapes',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildStep(context, 1, 'Le vendeur confirmera votre commande'),
          const SizedBox(height: 8),
          _buildStep(context, 2, 'Vous recevrez les détails de livraison'),
          const SizedBox(height: 8),
          _buildStep(context, 3, 'Suivez votre colis en temps réel'),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, int number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
