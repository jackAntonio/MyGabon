import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../services/kpay_service.dart';
import 'success_screen_complete.dart';

/// Écran de paiement Airtel Money avec intégration Kpay
class AirtelMoneyScreen extends StatefulWidget {
  final Product product;
  final double visibleFee;
  final double totalAmount;
  final String phoneNumber;

  const AirtelMoneyScreen({
    Key? key,
    required this.product,
    required this.visibleFee,
    required this.totalAmount,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<AirtelMoneyScreen> createState() => _AirtelMoneyScreenState();
}

class _AirtelMoneyScreenState extends State<AirtelMoneyScreen> {
  late final kpay = KpayService();
  String _transactionId = '';
  String _step = 'sending'; // sending, otp, confirming, success
  String _otp = '';
  bool _isLoading = false;
  int _secondsRemaining = 60;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      debugPrint('🔄 Initiating Airtel payment...');

      // Appeler Kpay pour initier le paiement
      final response = await kpay.initiateAirtelPayment(
        phoneNumber: widget.phoneNumber,
        amount: widget.totalAmount,
        productName: widget.product.title,
        productId: widget.product.id,
      );

      if (response.success) {
        setState(() {
          _transactionId = response.transactionId;
          _step = 'otp';
          _isLoading = false;
        });

        _startOtpTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Code OTP envoyé au ${widget.phoneNumber}',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw KpayException(response.message);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _step = 'error';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $_errorMessage'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _startOtpTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _secondsRemaining > 0 && _step == 'otp') {
        setState(() => _secondsRemaining--);
        _startOtpTimer();
      }
    });
  }

  Future<void> _confirmPayment() async {
    if (_otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le code OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      debugPrint('✔️ Confirming payment with OTP...');

      // Confirmer le paiement avec Kpay
      final response = await kpay.confirmAirtelPayment(
        transactionId: _transactionId,
        otp: _otp,
      );

      if (response.success) {
        setState(() {
          _step = 'success';
          _isLoading = false;
        });

        // Attendre 1 seconde avant de naviguer
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreenComplete(
              product: widget.product,
              totalAmount: widget.totalAmount,
              transactionId: _transactionId,
            ),
          ),
        );
      } else {
        throw KpayException(response.message);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur confirmation: $_errorMessage'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Animated phone icon
                  _buildAnimatedIcon(),
                  const SizedBox(height: 32),

                  // Title and subtitle
                  _buildHeader(),
                  const SizedBox(height: 40),

                  // Payment details
                  _buildPaymentDetails(),
                  const SizedBox(height: 40),

                  // Step indicator
                  _buildSteps(),
                  const SizedBox(height: 40),

                  // OTP input or confirmation
                  if (_step == 'otp') _buildOtpInput(),
                  if (_step == 'error') _buildErrorState(),
                  if (_step == 'sending') _buildSendingState(),

                  const SizedBox(height: 32),

                  // Action buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return Container(
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
        .scaleXY(begin: 1.0, end: 1.1, duration: const Duration(seconds: 2))
        .then()
        .scaleXY(begin: 1.1, end: 1.0, duration: const Duration(seconds: 2));
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Paiement Airtel Money',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Confirmez votre paiement sur votre téléphone Airtel',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.grey600,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
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
              Text('Montant à payer', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                kpayService.formatPrice(widget.totalAmount),
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
              Text('Numéro Airtel', style: Theme.of(context).textTheme.bodySmall),
              Text(
                widget.phoneNumber,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Produit', style: Theme.of(context).textTheme.bodySmall),
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

  Widget _buildSteps() {
    final currentStepIndex = _step == 'sending'
        ? 0
        : _step == 'otp'
            ? 1
            : 2;

    return Column(
      children: [
        _buildStep(1, 'Envoi du code', currentStepIndex >= 0),
        const SizedBox(height: 16),
        _buildStep(2, 'Vérification OTP', currentStepIndex >= 1),
        const SizedBox(height: 16),
        _buildStep(3, 'Paiement confirmé', currentStepIndex >= 2),
      ],
    );
  }

  Widget _buildStep(int number, String text, bool isDone) {
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

  Widget _buildSendingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Envoi du code OTP en cours...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Code OTP', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => setState(() => _otp = value),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
          decoration: InputDecoration(
            hintText: '000000',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        if (_secondsRemaining > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Code valide dans $_secondsRemaining secondes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Erreur de paiement',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.error,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_step == 'sending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.grey300,
          ),
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_step == 'error') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _initiatePayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                'Réessayer',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.white,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.grey700,
                    ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _confirmPayment,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.primary,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
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
    );
  }
}
