import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import 'success_screen.dart';

/// Airtel Money OTP/confirmation screen
class AirtelConfirmationScreen extends StatefulWidget {
  final Product product;
  final double visibleFee;
  final double totalAmount;

  const AirtelConfirmationScreen({
    Key? key,
    required this.product,
    required this.visibleFee,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<AirtelConfirmationScreen> createState() =>
      _AirtelConfirmationScreenState();
}

class _AirtelConfirmationScreenState extends State<AirtelConfirmationScreen> {
  bool _isConfirmed = false;
  bool _isLoading = false;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _secondsRemaining > 0 && !_isConfirmed) {
        setState(() => _secondsRemaining--);
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Phone icon animation
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      Icons.phone_in_talk_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scaleXY(begin: 1.0, end: 1.1, duration: 2000.ms)
                      .then()
                      .scaleXY(begin: 1.1, end: 1.0, duration: 2000.ms),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Confirmation Airtel Money',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Un message a été envoyé à votre numéro Airtel.\nVeuillez confirmer le paiement sur votre téléphone.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Payment details
                  _buildPaymentDetails(context),
                  const SizedBox(height: 40),

                  // Steps
                  _buildSteps(context),
                  const SizedBox(height: 40),

                  // Confirm button or timer
                  _isConfirmed
                      ? _buildConfirmedState()
                      : _buildConfirmationUI(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Montant à payer',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey600,
                    ),
              ),
              Text(
                _formatPrice(widget.totalAmount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.grey300),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Produit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey600,
                    ),
              ),
              Text(
                widget.product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSteps(BuildContext context) {
    return Column(
      children: [
        _buildStep(context, 1, 'Vérifiez votre téléphone Airtel', _isConfirmed),
        const SizedBox(height: 16),
        _buildStep(context, 2, 'Validez le montant et l\'OTP',
            _isConfirmed && _secondsRemaining > 0),
        const SizedBox(height: 16),
        _buildStep(context, 3, 'Paiement confirmé', _isConfirmed),
      ],
    );
  }

  Widget _buildStep(BuildContext context, int number, String text, bool isDone) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDone ? AppColors.success : AppColors.grey300,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: AppColors.white, size: 18)
                : Text(
                    '$number',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDone ? AppColors.grey900 : AppColors.grey600,
                  fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationUI(BuildContext context) {
    return Column(
      children: [
        if (_secondsRemaining > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Veuillez confirmer dans $_secondsRemaining secondes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.warning,
                        ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _confirmPayment(context),
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white),
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(
            _isLoading ? 'Confirmation...' : 'Confirmer le paiement',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.white,
                ),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            backgroundColor: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Annuler',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmedState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Paiement confirmé!',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPayment(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      // Simulate payment confirmation
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isConfirmed = true);

      // Navigate to success screen after a brief delay
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            product: widget.product,
            totalAmount: widget.totalAmount,
            transactionId: 'AIRTEL_${DateTime.now().millisecondsSinceEpoch}',
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
      setState(() => _isLoading = false);
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
