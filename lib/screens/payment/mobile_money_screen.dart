import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../services/kpay_service.dart';
import '../../services/supabase_service.dart';
import 'success_screen.dart';

/// Écran de paiement Airtel Money (Gabon) avec intégration Kpay.
///
/// La doc officielle Kpay ne décrit aucune étape de confirmation par OTP
/// dans l'app : après l'initiation, l'utilisateur valide directement sur
/// son téléphone (USSD Airtel). Le statut final n'arrive que via le
/// webhook serveur (jamais déclaré par ce client) ; cet écran attend
/// simplement cette confirmation via Supabase Realtime.
class MobileMoneyScreen extends StatefulWidget {
  final Product product;
  final double visibleFee;
  final double totalAmount;
  final String phoneNumber;

  const MobileMoneyScreen({
    super.key,
    required this.product,
    required this.visibleFee,
    required this.totalAmount,
    required this.phoneNumber,
  });

  @override
  State<MobileMoneyScreen> createState() => _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends State<MobileMoneyScreen> {
  late final kpay = KpayService();
  String? _supabaseTransactionId;
  String _step = 'sending'; // sending, waiting_server, error, success
  bool _isLoading = false;
  String _errorMessage = '';
  StreamSubscription<Map<String, dynamic>?>? _statusSubscription;
  Timer? _serverTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _serverTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _step = 'sending';
    });

    try {
      debugPrint('🔄 Initiating Airtel Money payment...');

      // ✅ La transaction Supabase est créée avant l'appel Kpay : son ID
      // sert d'externalId envoyé à Kpay, pour que le webhook (confirmé
      // côté serveur) puisse la retrouver directement.
      final supabaseTransactionId = await SupabaseService().createTransaction(
        sellerId: widget.product.sellerId,
        productId: widget.product.id,
        grossAmount: widget.product.price,
        paymentMethod: 'airtel_money',
      );

      if (supabaseTransactionId == null) {
        throw Exception('Impossible de créer la transaction');
      }
      _supabaseTransactionId = supabaseTransactionId;

      final response = await kpay.initiateAirtelMoneyPayment(
        transactionId: supabaseTransactionId,
        phoneNumber: widget.phoneNumber,
      );

      if (response.success) {
        setState(() {
          _step = 'waiting_server';
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Validez le paiement sur votre téléphone (${widget.phoneNumber})'),
              backgroundColor: AppColors.success,
            ),
          );
        }

        _waitForServerConfirmation();
      } else {
        throw KpayException(response.message ?? 'Erreur initiation paiement');
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

  /// Observe la transaction Supabase jusqu'à ce que le webhook Kpay
  /// (server-to-server) la marque 'success' ou 'failed'. Timeout de 30s :
  /// le paiement continue en arrière-plan même si l'utilisateur quitte
  /// l'écran (la confirmation finale sera visible dans l'historique).
  void _waitForServerConfirmation() {
    if (_supabaseTransactionId == null) return;

    _statusSubscription = SupabaseService()
        .watchTransactionStatus(_supabaseTransactionId!)
        .listen((row) {
      final status = row?['status'] as String?;
      if (status == 'success') {
        _statusSubscription?.cancel();
        _serverTimeoutTimer?.cancel();
        if (!mounted) return;
        setState(() => _step = 'success');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              product: widget.product,
              totalAmount: widget.totalAmount,
              transactionId: _supabaseTransactionId!,
            ),
          ),
        );
      } else if (status == 'failed') {
        _statusSubscription?.cancel();
        _serverTimeoutTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _step = 'error';
          _errorMessage = row?['notes'] as String? ??
              'Le paiement a été refusé par Airtel Money';
        });
      }
    });

    _serverTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || _step != 'waiting_server') return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La confirmation prend plus de temps que prévu. '
            'Vous serez notifié dès que le paiement sera confirmé.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 'waiting_server' || _step == 'error',
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildAnimatedIcon(),
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildPaymentDetails(),
                  const SizedBox(height: 40),
                  _buildSteps(),
                  const SizedBox(height: 40),
                  if (_step == 'error') _buildErrorState(),
                  if (_step == 'sending') _buildSendingState(),
                  if (_step == 'waiting_server') _buildWaitingServerState(),
                  const SizedBox(height: 32),
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
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Icon(
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
          'Validez le paiement directement sur votre téléphone',
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
              Text('Montant à payer',
                  style: Theme.of(context).textTheme.bodyMedium),
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
              Text('Numéro Airtel Money',
                  style: Theme.of(context).textTheme.bodySmall),
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
        : _step == 'success'
            ? 2
            : 1;

    return Column(
      children: [
        _buildStep(1, 'Initiation du paiement', currentStepIndex >= 0),
        const SizedBox(height: 16),
        _buildStep(2, 'Validation sur votre téléphone', currentStepIndex >= 1),
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
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
              'Initiation du paiement en cours...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingServerState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
              'En attente de votre validation sur votre téléphone...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
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
              onPressed: _isLoading ? null : _initiatePayment,
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

    if (_step == 'waiting_server') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Continuer en arrière-plan'),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
