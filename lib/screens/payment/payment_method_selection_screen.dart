import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../services/payment_service.dart';
import 'checkout_screen.dart';
import 'airtel_confirmation_screen.dart';

/// Écran de sélection de méthode de paiement (Apple Pay + Options existantes)
class PaymentMethodSelectionScreen extends StatefulWidget {
  final Product product;

  const PaymentMethodSelectionScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<PaymentMethodSelectionScreen> createState() =>
      _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState
    extends State<PaymentMethodSelectionScreen> {
  String _selectedMethod = 'mygabon'; // Défaut

  @override
  Widget build(BuildContext context) {
    final fees = PaymentService.calculateFees(widget.product.price);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Méthode de paiement'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé du produit
            _buildProductSummary(context, fees),
            const SizedBox(height: 32),

            // Titre des méthodes
            Text(
              'Choisir une méthode de paiement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Option 1: Apple Pay
            _buildPaymentOption(
              context,
              icon: '🍎',
              title: 'Apple Pay',
              subtitle: 'Paiement sécurisé avec Apple Pay',
              value: 'apple_pay',
              isNew: true,
            ),

            const SizedBox(height: 12),

            // Option 2: Google Pay
            _buildPaymentOption(
              context,
              icon: '🔵',
              title: 'Google Pay',
              subtitle: 'Paiement rapide avec Google Pay',
              value: 'google_pay',
              isNew: true,
            ),

            const SizedBox(height: 12),

            // Option 3: MyGabon Wallet
            _buildPaymentOption(
              context,
              icon: '💰',
              title: 'MyGabon Wallet',
              subtitle: 'Solde: 485 750 FCFA',
              value: 'mygabon',
            ),

            const SizedBox(height: 12),

            // Option 4: Airtel Money
            _buildPaymentOption(
              context,
              icon: '📱',
              title: 'Airtel Money',
              subtitle: 'Paiement par SMS OTP',
              value: 'airtel',
            ),

            const SizedBox(height: 12),

            // Option 5: Cash
            _buildPaymentOption(
              context,
              icon: '💵',
              title: 'Paiement en espèces',
              subtitle: 'À confirmer avec le vendeur',
              value: 'cash',
            ),

            const SizedBox(height: 32),

            // Bouton Continuer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handlePayment(context, fees),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  'Continuer',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.white,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info de sécurité
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: AppColors.info,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vos paiements sont sécurisés et chiffrés',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.info,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSummary(
    BuildContext context,
    FeeCalculation fees,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prix du produit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey600,
                ),
              ),
              Text(
                widget.product.formattedPrice,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Frais (5%)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey600,
                ),
              ),
              Text(
                '${fees.visibleFee.toStringAsFixed(0)} FCFA',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: AppColors.grey200,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total à payer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${fees.totalWithVisibleFee.toStringAsFixed(0)} FCFA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required String value,
    bool isNew = false,
  }) {
    final isSelected = _selectedMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),

            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isNew)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NOUVEAU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),

            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.grey300,
                  width: isSelected ? 6 : 2,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _handlePayment(BuildContext context, FeeCalculation fees) {
    switch (_selectedMethod) {
      case 'apple_pay':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Apple Pay - Intégration en cours...'),
            backgroundColor: AppColors.info,
          ),
        );
        // TODO: Intégrer ApplePayService
        break;

      case 'google_pay':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Google Pay - Intégration en cours...'),
            backgroundColor: AppColors.info,
          ),
        );
        // TODO: Intégrer GooglePayService
        break;

      case 'mygabon':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutScreen(product: widget.product),
          ),
        );
        break;

      case 'airtel':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AirtelConfirmationScreen(
              product: widget.product,
              visibleFee: fees.visibleFee,
              totalAmount: fees.totalWithVisibleFee,
            ),
          ),
        );
        break;

      case 'cash':
        _showCashModal(context, fees);
        break;
    }
  }

  void _showCashModal(BuildContext context, FeeCalculation fees) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paiement en espèces',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Montant à payer',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${fees.totalWithVisibleFee.toStringAsFixed(0)} FCFA',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Instructions:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(context, 1, 'Contactez le vendeur'),
            _buildInstructionStep(context, 2, 'Convenus du lieu de rendez-vous'),
            _buildInstructionStep(context, 3, 'Effectuez le paiement en espèces'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Comprendre'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(BuildContext context, int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
