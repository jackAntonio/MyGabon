import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../services/payment_service.dart';
import 'airtel_confirmation_screen.dart';

/// Checkout summary screen showing item, price, and 5% fee
class CheckoutScreen extends StatefulWidget {
  final Product product;

  const CheckoutScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final fees = PaymentService.calculateFees(widget.product.price);
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé de commande'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order summary card
              _buildOrderSummary(context),
              const SizedBox(height: 32),

              // Payment method selection
              _buildPaymentMethods(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé de votre commande',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),

          // Item
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
                      AppColors.primary.withOpacity(0.3),
                      AppColors.accent.withOpacity(0.2),
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
                      widget.product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vendeur: ${widget.product.sellerName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.grey300),
          const SizedBox(height: 20),

          // Price breakdown
          _buildPriceBreakdown(context),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(BuildContext context) {
    return Column(
      children: [
        // Price row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prix du produit',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              widget.product.formattedPrice,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Fee row (5% visible only)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Frais de service',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+ ${_formatPrice(fees.visibleFee)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 1,
          color: AppColors.grey300,
        ),
        const SizedBox(height: 20),

        // Total row
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
              _formatPrice(fees.totalWithVisibleFee),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethods(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode de paiement',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),

        // MyGabon Wallet option
        _buildPaymentOption(
          context,
          icon: Icons.wallet_outlined,
          title: 'Portefeuille MyGabon',
          subtitle: 'Paiement instantané avec votre solde',
          isSelected: true,
        ),
        const SizedBox(height: 12),

        // Airtel Money option
        _buildPaymentOption(
          context,
          icon: Icons.phone_outlined,
          title: 'Airtel Money',
          subtitle: 'Confirmation par SMS',
          isSelected: false,
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.white,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.grey200,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? AppColors.primary : AppColors.grey500),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.grey900,
                      ),
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
          if (isSelected)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.white,
                size: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
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
            onPressed: _isProcessing
                ? null
                : () => _processPayment(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Confirmer le paiement',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.white,
                        ),
                  ),
          ),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      // Navigate to Airtel Money confirmation
      if (!mounted) return;
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
}
