import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/kpay_service.dart';
import '../services/supabase_service.dart';
import '../utils/validators.dart';

/// Recharge du MyGabon Wallet via Airtel Money (Kpay).
///
/// Même principe que MobileMoneyScreen (paiement marketplace) : l'app
/// initie le paiement puis attend la confirmation serveur via Supabase
/// Realtime — jamais déclarée par ce client (cf. SupabaseService.
/// watchWalletTopupStatus).
class WalletTopUpScreen extends StatefulWidget {
  const WalletTopUpScreen({Key? key}) : super(key: key);

  @override
  State<WalletTopUpScreen> createState() => _WalletTopUpScreenState();
}

class _WalletTopUpScreenState extends State<WalletTopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final kpay = KpayService();

  String _step = 'form'; // form, sending, waiting_server, success, error
  String _errorMessage = '';
  String? _topupId;
  StreamSubscription<Map<String, dynamic>?>? _statusSubscription;
  Timer? _serverTimeoutTimer;

  static const double _minAmount = 1000;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _statusSubscription?.cancel();
    _serverTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.parse(_amountController.text);
    setState(() {
      _step = 'sending';
      _errorMessage = '';
    });

    try {
      final topupId = await SupabaseService().createWalletTopup(
        amount: amount,
        paymentMethod: 'airtel_money',
      );
      if (topupId == null) {
        throw Exception('Impossible de créer la recharge');
      }
      _topupId = topupId;

      final response = await kpay.initiateWalletTopUp(
        topupId: topupId,
        phoneNumber: _phoneController.text,
      );

      if (!response.success) {
        throw KpayException(response.message ?? 'Erreur initiation recharge');
      }

      setState(() => _step = 'waiting_server');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Validez la recharge sur votre téléphone (${_phoneController.text})'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _waitForServerConfirmation();
    } catch (e) {
      setState(() {
        _step = 'error';
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _waitForServerConfirmation() {
    if (_topupId == null) return;

    _statusSubscription =
        SupabaseService().watchWalletTopupStatus(_topupId!).listen((row) {
      final status = row?['status'] as String?;
      if (status == 'success') {
        _statusSubscription?.cancel();
        _serverTimeoutTimer?.cancel();
        if (!mounted) return;
        setState(() => _step = 'success');
      } else if (status == 'failed') {
        _statusSubscription?.cancel();
        _serverTimeoutTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _step = 'error';
          _errorMessage = row?['notes'] as String? ??
              'La recharge a été refusée par Airtel Money';
        });
      }
    });

    _serverTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || _step != 'waiting_server') return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La confirmation prend plus de temps que prévu. '
            'Votre solde sera mis à jour dès que la recharge sera confirmée.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
    });
  }

  void _reset() {
    setState(() {
      _step = 'form';
      _errorMessage = '';
      _topupId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recharger mon wallet')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: switch (_step) {
            'success' => _buildSuccess(context),
            'error' => _buildForm(context, error: _errorMessage),
            'sending' || 'waiting_server' => _buildWaiting(context),
            _ => _buildForm(context),
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {String? error}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recharger via Airtel Money',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Le montant sera ajouté à votre solde MyGabon Wallet dès confirmation du paiement.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          const SizedBox(height: 24),
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Text(error, style: const TextStyle(color: AppColors.error)),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant à recharger',
              suffixText: 'FCFA',
            ),
            validator: (value) {
              final amount = double.tryParse(value ?? '');
              if (amount == null) return 'Montant invalide';
              if (amount < _minAmount) {
                return 'Minimum ${_minAmount.toStringAsFixed(0)} FCFA';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Numéro Airtel Money',
              hintText: '+241 06 XX XX XX',
            ),
            validator: Validators.validatePhone,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Recharger'),
          ),
        ],
      ),
    );
  }

  Widget _buildWaiting(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.phone_in_talk_outlined,
              size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        Text(
          _step == 'sending'
              ? 'Initiation de la recharge...'
              : 'En attente de votre validation sur votre téléphone...',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 32),
        if (_step == 'waiting_server')
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer en arrière-plan'),
          ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.check_circle,
              size: 48, color: AppColors.success),
        ),
        const SizedBox(height: 24),
        Text(
          'Recharge réussie !',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Votre solde MyGabon Wallet a été mis à jour.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey600,
              ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Retour'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _reset,
          child: const Text('Faire une autre recharge'),
        ),
      ],
    );
  }
}
