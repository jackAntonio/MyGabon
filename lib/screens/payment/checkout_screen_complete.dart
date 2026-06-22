import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../services/payment_service.dart';
import '../../services/supabase_provider.dart';
import 'airtel_confirmation_screen.dart';

class CheckoutScreenComplete extends ConsumerStatefulWidget {
  final Product product;

  const CheckoutScreenComplete({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  ConsumerState<CheckoutScreenComplete> createState() => _CheckoutScreenCompleteState();
}

class _CheckoutScreenCompleteState extends ConsumerState<CheckoutScreenComplete> {
  late final fees = PaymentService.calculateFees(widget.product.price);
  String _selectedPaymentMethod = 'my_gabon';
  bool _isProcessing = false;
  String _phoneNumber = '';

  @override
  Widget build(BuildContext context) {
    final walletBalance = ref.watch(userWalletProvider);

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
              // Order summary
              _buildOrderSummary(context),
              const SizedBox(height: 32),

              // Wallet balance (for MyGabon)
              if (_selectedPaymentMethod == 'my_gabon')
                walletBalance.when(
                  data: (balance) => _buildWalletInfo(context, balance),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => _buildWalletError(context),
                ),
              const SizedBox(height: 24),

              // Payment method selection
              _buildPaymentMethods(context),
              const SizedBox(height: 24),

              // Phone number for Airtel
              if (_selectedPaymentMethod == 'airtel_money')
                _buildPhoneInput(context),
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
                child: Icon(Icons.shopping_bag, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product.title, style: Theme.of(context).textTheme.titleSmall),
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
          const SizedBox(height: 20),
          const Divider(color: AppColors.grey300),
          const SizedBox(height: 20),

          // Price breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prix', style: Theme.of(context).textTheme.bodyMedium),
              Text('${_formatPrice(widget.product.price)}', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Frais MyGabon (5%)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.grey600)),
              Text('${_formatPrice(fees.visibleFee)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.grey600)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.primary, thickness: 2),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                _formatPrice(fees.totalWithVisibleFee),
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

  Widget _buildWalletInfo(BuildContext context, double balance) {
    final hasSufficientBalance = balance >= fees.totalWithVisibleFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasSufficientBalance
            ? AppColors.success.withOpacity(0.05)
            : AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSufficientBalance
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasSufficientBalance ? Icons.wallet : Icons.wallet_outlined,
            color: hasSufficientBalance ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portefeuille MyGabon',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Solde: ${_formatPrice(balance)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: hasSufficientBalance ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('Erreur lors de la récupération du solde'),
    );
  }

  Widget _buildPaymentMethods(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthode de paiement',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _buildPaymentOption(
          context,
          title: 'MyGabon Wallet',
          subtitle: 'Paiement instantané via portefeuille',
          value: 'my_gabon',
          icon: Icons.account_balance_wallet,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          context,
          title: 'Airtel Money',
          subtitle: 'Paiement par téléphone mobile',
          value: 'airtel_money',
          icon: Icons.phone_in_talk,
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.grey200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? AppColors.white : AppColors.grey600),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
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
              Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Numéro Airtel', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) => setState(() => _phoneNumber = value),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+241XXXXXXXX ou 06XXXXXXXX',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Procéder au paiement',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.white,
                      ),
                ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'airtel_money' && _phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre numéro Airtel'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (_selectedPaymentMethod == 'airtel_money') {
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
      } else {
        // MyGabon Wallet payment
        final walletBalance = await ref.read(userWalletProvider.future);

        if (walletBalance < fees.totalWithVisibleFee) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solde insuffisant'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        // Simulate payment success
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/payment-success',
          arguments: {
            'product': widget.product,
            'amount': fees.totalWithVisibleFee,
            'transactionId': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _formatPrice(double amount) {
    return '${amount.toStringAsFixed(0)} FCFA';
  }
}
