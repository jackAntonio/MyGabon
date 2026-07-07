import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../services/payment_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_scaffold.dart';
import '../wallet_topup_screen.dart';

/// Paiement groupé de tout le panier via le MyGabon Wallet (RPC
/// complete_cart_checkout, atomique côté serveur : tout le panier passe
/// ou rien ne passe). Remplace le paiement article par article pour les
/// utilisateurs qui veulent tout payer en un coup — "Payer cet article"
/// reste disponible pour Airtel Money/espèces/Apple/Google Pay, que
/// cette RPC ne gère pas (un prélèvement Kpay par article nécessiterait
/// plusieurs validations USSD successives, hors périmètre ici).
class CartCheckoutScreen extends StatefulWidget {
  const CartCheckoutScreen({super.key});

  @override
  State<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends State<CartCheckoutScreen> {
  double? _walletBalance;
  bool _loadingWallet = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return;
    final balance = await SupabaseService().getWalletBalance(userId);
    if (mounted) {
      setState(() {
        _walletBalance = balance;
        _loadingWallet = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;

    double itemsTotal = 0;
    double feesTotal = 0;
    for (final entry in items) {
      final fees = PaymentService.calculateFees(entry.key.price * entry.value);
      itemsTotal += entry.key.price * entry.value;
      feesTotal += fees.visibleFee;
    }
    final deliveryFee = items.isEmpty ? 0.0 : PaymentService.standardDeliveryFee;
    final grandTotal = itemsTotal + feesTotal + deliveryFee;
    final insufficientBalance =
        !_loadingWallet && (_walletBalance ?? 0) < grandTotal;

    return AppScaffold(
      appBar: AppBar(title: const Text('Payer le panier')),
      body: items.isEmpty
          ? const Center(child: Text('Panier vide'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Résumé de la commande',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Column(
                      children: [
                        for (final entry in items) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${entry.key.title} × ${entry.value}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                '${(entry.key.price * entry.value).toStringAsFixed(0)} FCFA',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        const Divider(),
                        _summaryRow(context, 'Frais de service (5%)',
                            feesTotal, false),
                        const SizedBox(height: 8),
                        _summaryRow(context, 'Livraison (un seul livreur)',
                            deliveryFee, false),
                        const SizedBox(height: 12),
                        const Divider(),
                        _summaryRow(context, 'Total à payer', grandTotal, true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success.withValues(alpha: 0.15),
                          AppColors.accent.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Solde MyGabon Wallet',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                          _loadingWallet
                              ? '...'
                              : '${_walletBalance!.toStringAsFixed(0)} FCFA',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: insufficientBalance
                                    ? AppColors.error
                                    : AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (insufficientBalance) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Recharger le wallet'),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WalletTopUpScreen()),
                          );
                          _loadWalletBalance();
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing || insufficientBalance
                          ? null
                          : () => _confirmPayment(context, cart, items),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(AppColors.white),
                              ),
                            )
                          : const Text('Payer le panier'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _summaryRow(
      BuildContext context, String label, double amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)
              : Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.grey600),
        ),
        Text(
          '${amount.toStringAsFixed(0)} FCFA',
          style: isTotal
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  )
              : Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _confirmPayment(
    BuildContext context,
    CartProvider cart,
    List<MapEntry<Product, int>> items,
  ) async {
    setState(() => _isProcessing = true);
    try {
      final transactionIds = await SupabaseService().completeCartCheckout([
        for (final entry in items)
          (productId: entry.key.id, quantity: entry.value),
      ]);

      cart.clear();

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Paiement réussi'),
          content: Text(
            '${transactionIds.length} article${transactionIds.length > 1 ? 's' : ''} payé${transactionIds.length > 1 ? 's' : ''} avec succès.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // ferme le dialog
                Navigator.pop(context); // retourne au panier (vide)
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
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
}
