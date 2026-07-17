import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../services/payment_service.dart';
import '../../services/apple_pay_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/validators.dart';
import '../../widgets/app_scaffold.dart';
import 'mobile_money_screen.dart';
import 'success_screen.dart';

/// Écran de sélection de méthode de paiement : MyGabon Wallet et Airtel Money
/// en priorité (marché gabonais), paiement à la livraison quand un livreur
/// est dans la boucle, Apple Pay / Google Pay en options additionnelles,
/// paiement en espèces de gré à gré en dernier recours.
class PaymentMethodSelectionScreen extends StatefulWidget {
  final Product product;
  final double deliveryFee;

  const PaymentMethodSelectionScreen({
    super.key,
    required this.product,
    this.deliveryFee = 0,
  });

  @override
  State<PaymentMethodSelectionScreen> createState() =>
      _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState
    extends State<PaymentMethodSelectionScreen> {
  String _selectedMethod = 'mygabon'; // Défaut
  String _phoneNumber = '';
  bool _isProcessing = false;
  double? _walletBalance;
  bool _codEligible = true;
  String? _codReason;

  /// Le paiement à la livraison suppose un livreur MyGabon pour encaisser :
  /// sans frais de livraison sur cette commande, l'option n'a pas de sens
  /// (le serveur la refuserait de toute façon).
  bool get _codAvailable => widget.deliveryFee > 0;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
    if (_codAvailable) _loadCodEligibility();
  }

  Future<void> _loadWalletBalance() async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return;
    final balance = await SupabaseService().getWalletBalance(userId);
    if (mounted) setState(() => _walletBalance = balance);
  }

  Future<void> _loadCodEligibility() async {
    final result = await SupabaseService().checkCodEligibility();
    if (!mounted) return;
    setState(() {
      _codEligible = result.eligible;
      _codReason = result.reason;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fees = PaymentService.calculateFees(widget.product.price);

    return AppScaffold(
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

            // Option 1: MyGabon Wallet
            _buildPaymentOption(
              context,
              icon: '💰',
              title: 'MyGabon Wallet',
              subtitle: _walletBalance == null
                  ? 'Chargement du solde...'
                  : 'Solde : ${_walletBalance!.toStringAsFixed(0)} FCFA',
              value: 'mygabon',
            ),

            const SizedBox(height: 12),

            // Option 2: Airtel Money
            _buildPaymentOption(
              context,
              icon: '📱',
              title: 'Airtel Money',
              subtitle: 'Validation directe sur votre téléphone',
              value: 'airtel',
            ),

            // Option 3: Paiement à la livraison (seulement si un livreur
            // MyGabon est dans la boucle — c'est lui qui encaisse)
            if (_codAvailable) ...[
              const SizedBox(height: 12),
              _buildPaymentOption(
                context,
                icon: '🛵',
                title: 'Paiement à la livraison',
                subtitle: _codEligible
                    ? 'Payez en espèces au livreur à la remise du colis'
                    : (_codReason ?? 'Indisponible sur votre compte'),
                value: 'cash_on_delivery',
                enabled: _codEligible,
              ),
            ],

            const SizedBox(height: 12),

            // Option 4: Cash de gré à gré (sans livreur)
            _buildPaymentOption(
              context,
              icon: '💵',
              title: 'Paiement en espèces',
              subtitle: 'À confirmer avec le vendeur',
              value: 'cash',
            ),

            // Numéro Airtel Money (affiché seulement si Airtel sélectionné)
            if (_selectedMethod == 'airtel') ...[
              const SizedBox(height: 16),
              _buildPhoneInput(context),
            ],

            const SizedBox(height: 24),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: AppColors.grey200),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Autres options de paiement',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey600,
                      ),
                ),
                children: [
                  // Option : Apple Pay
                  _buildPaymentOption(
                    context,
                    icon: '🍎',
                    title: 'Apple Pay',
                    subtitle: 'Paiement sécurisé avec Apple Pay',
                    value: 'apple_pay',
                  ),
                  const SizedBox(height: 12),
                  // Option : Google Pay
                  _buildPaymentOption(
                    context,
                    icon: '🔵',
                    title: 'Google Pay',
                    subtitle: 'Paiement rapide avec Google Pay',
                    value: 'google_pay',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Bouton Continuer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _handlePayment(context, fees),
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
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
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
          if (widget.deliveryFee > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Frais de livraison',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
                Text(
                  '${widget.deliveryFee.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
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
                '${(fees.totalWithVisibleFee + widget.deliveryFee).toStringAsFixed(0)} FCFA',
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

  Widget _buildPhoneInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Numéro Airtel Money', style: Theme.of(context).textTheme.titleSmall),
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

  Widget _buildPaymentOption(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required String value,
    bool isNew = false,
    bool enabled = true,
  }) {
    final isSelected = _selectedMethod == value;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? () => setState(() => _selectedMethod = value) : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.white,
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
                            child: const Text(
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
      ),
    );
  }

  void _handlePayment(BuildContext context, FeeCalculation fees) {
    switch (_selectedMethod) {
      case 'apple_pay':
        _handleExternalWalletPayment(context, fees, isApplePay: true);
        break;

      case 'google_pay':
        _handleExternalWalletPayment(context, fees, isApplePay: false);
        break;

      case 'mygabon':
        _handleMyGabonPayment(context, fees);
        break;

      case 'airtel':
        _handleMobileMoneyPayment(context, fees);
        break;

      case 'cash_on_delivery':
        _handleCashOnDeliveryOrder(context, fees);
        break;

      case 'cash':
        _handleCashPayment(context, fees);
        break;
    }
  }

  /// Paiement à la livraison : la commande part sans qu'un centime ne bouge.
  /// C'est le livreur qui encaissera les espèces à la remise du colis et qui,
  /// seul, pourra créditer le vendeur (RPC confirm_cash_on_delivery) — d'où
  /// le passage par create_cash_on_delivery_order plutôt que par
  /// createTransaction : le serveur y dérive lui-même vendeur/prix/frais et
  /// vérifie l'éligibilité de l'acheteur.
  Future<void> _handleCashOnDeliveryOrder(
    BuildContext context,
    FeeCalculation fees,
  ) async {
    setState(() => _isProcessing = true);
    try {
      await SupabaseService().createCashOnDeliveryOrder(widget.product.id);

      if (!context.mounted) return;
      _showCashOnDeliveryModal(context, fees);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showCashOnDeliveryModal(BuildContext context, FeeCalculation fees) {
    final totalDue = fees.totalWithVisibleFee + widget.deliveryFee;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commande confirmée',
              style: Theme.of(modalContext).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À préparer en espèces',
                    style: Theme.of(modalContext).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${totalDue.toStringAsFixed(0)} FCFA',
                    style: Theme.of(modalContext).textTheme.displaySmall?.copyWith(
                          color: AppColors.success,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Frais de livraison inclus',
                    style: Theme.of(modalContext).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Prochaines étapes :',
              style: Theme.of(modalContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
                modalContext, 1, 'Un livreur prend en charge votre commande'),
            _buildInstructionStep(
                modalContext, 2, 'Vous êtes notifié quand il part'),
            _buildInstructionStep(
                modalContext, 3, 'Vous payez en espèces à la remise du colis'),
            const SizedBox(height: 16),
            Text(
              'Suivez l\'avancement dans « Mes commandes ». Un refus de paiement '
              'à la livraison peut suspendre votre accès à ce mode de paiement.',
              style: Theme.of(modalContext).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(modalContext); // ferme le modal
                  Navigator.pop(context); // quitte l'écran de paiement
                },
                child: const Text('Compris'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Paiement via le portefeuille MyGabon : débite l'acheteur, crédite le
  /// vendeur de façon atomique côté serveur (RPC complete_marketplace_transaction).
  Future<void> _handleMyGabonPayment(
    BuildContext context,
    FeeCalculation fees,
  ) async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return;

    final totalDue = fees.totalWithVisibleFee + widget.deliveryFee;

    setState(() => _isProcessing = true);
    try {
      final balance = await SupabaseService().getWalletBalance(userId);
      if (balance < totalDue) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solde insuffisant'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final transactionId = await SupabaseService().createTransaction(
        sellerId: widget.product.sellerId,
        productId: widget.product.id,
        grossAmount: widget.product.price,
        paymentMethod: 'mygabon_wallet',
        deliveryFee: widget.deliveryFee,
      );

      if (transactionId == null) {
        throw Exception('Impossible de créer la transaction');
      }

      final success =
          await SupabaseService().completeMarketplaceTransaction(transactionId);
      if (!success) {
        throw Exception('Le paiement a échoué');
      }

      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            product: widget.product,
            totalAmount: totalDue,
            transactionId: transactionId,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleMobileMoneyPayment(
    BuildContext context,
    FeeCalculation fees,
  ) {
    if (Validators.validatePhone(_phoneNumber) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un numéro Airtel Money valide'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileMoneyScreen(
          product: widget.product,
          visibleFee: fees.visibleFee,
          totalAmount: fees.totalWithVisibleFee,
          phoneNumber: _phoneNumber,
        ),
      ),
    );
  }

  /// Apple Pay / Google Pay : `service.processPayment` ne fait que valider
  /// le sheet natif via le gateway de test "example" (cf. apple_pay_service.dart)
  /// — aucun vrai processeur de paiement n'est branché, donc aucune carte
  /// n'est réellement débitée. On enregistre quand même la transaction côté
  /// Supabase (pour qu'elle soit tracée), mais on NE LA COMPLÈTE PAS
  /// automatiquement : il n'existe aucune vérification serveur du paiement
  /// ici (contrairement à Wallet et Airtel Money), donc la créditer comme
  /// "success" sur la seule foi du client réintroduirait la faille déjà
  /// corrigée pour Kpay (cf. migration 20260625_kpay_external_payment.sql).
  /// Elle reste 'pending' jusqu'à l'intégration d'un vrai processeur.
  Future<void> _handleExternalWalletPayment(
    BuildContext context,
    FeeCalculation fees, {
    required bool isApplePay,
  }) async {
    final service = applePayService;
    final available = isApplePay
        ? await service.isAvailable()
        : await service.isGooglePayAvailable();

    if (!available) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApplePay
                ? 'Apple Pay non disponible sur cet appareil'
                : 'Google Pay non disponible sur cet appareil',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final success = isApplePay
        ? await service.processPayment(
            product: widget.product,
            totalAmount: fees.totalWithVisibleFee,
            visibleFee: fees.visibleFee,
            countryCode: 'GA',
          )
        : await service.processGooglePayment(
            product: widget.product,
            totalAmount: fees.totalWithVisibleFee,
            visibleFee: fees.visibleFee,
          );

    if (!context.mounted) return;

    if (success) {
      final transactionId = await SupabaseService().createTransaction(
        sellerId: widget.product.sellerId,
        productId: widget.product.id,
        grossAmount: widget.product.price,
        paymentMethod: isApplePay ? 'apple_pay' : 'google_pay',
        deliveryFee: widget.deliveryFee,
      );

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            product: widget.product,
            totalAmount: fees.totalWithVisibleFee,
            transactionId: transactionId ?? '',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isApplePay
              ? 'Paiement Apple Pay annulé ou échoué'
              : 'Paiement Google Pay annulé ou échoué'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Paiement en espèces : enregistre une transaction 'pending' côté
  /// Supabase (traçabilité — avant ce correctif, aucune trace n'était
  /// créée). Reste 'pending' : seul un accord physique entre acheteur et
  /// vendeur finalise réellement ce paiement, aucune RPC ne le complète
  /// automatiquement.
  Future<void> _handleCashPayment(BuildContext context, FeeCalculation fees) async {
    final transactionId = await SupabaseService().createTransaction(
      sellerId: widget.product.sellerId,
      productId: widget.product.id,
      grossAmount: widget.product.price,
      paymentMethod: 'cash',
      deliveryFee: widget.deliveryFee,
    );

    if (!context.mounted) return;

    if (transactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'enregistrer la transaction'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _showCashModal(context, fees);
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
                color: AppColors.warning.withValues(alpha: 0.1),
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
            _buildInstructionStep(context, 2, 'Convenez du lieu de rendez-vous'),
            _buildInstructionStep(context, 3, 'Effectuez le paiement en espèces'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Compris'),
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
            decoration: const BoxDecoration(
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
