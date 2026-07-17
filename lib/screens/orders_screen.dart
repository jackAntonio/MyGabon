import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';
import '../widgets/app_scaffold.dart';

/// Historique complet des commandes (achats et ventes), avec statut de
/// livraison — jusqu'ici seul un aperçu tronqué vivait dans profile_screen,
/// sans titre de produit ni suivi de livraison.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  static const _deliveryLabels = {
    'none': 'Pas de livraison',
    'pending': 'En attente d\'un livreur',
    'claimed': 'Livreur en route',
    'delivered': 'Livré',
    'returned': 'Retourné (non réglé)',
  };

  static const _deliveryIcons = {
    'none': Icons.storefront_outlined,
    'pending': Icons.hourglass_top,
    'claimed': Icons.local_shipping_outlined,
    'delivered': Icons.check_circle_outline,
    'returned': Icons.assignment_return_outlined,
  };

  // Le statut brut de la base ('pending'/'success'/'failed') n'a rien à faire
  // sous les yeux d'un acheteur, d'autant que le COD rend l'état 'failed'
  // (paiement refusé à la remise) réellement visible.
  static const _statusLabels = {
    'pending': 'En attente',
    'success': 'Payé',
    'failed': 'Annulé',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return;
    setState(() => _loading = true);
    final orders = await SupabaseService().getUserOrders(userId);
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Aucune commande pour le moment',
                          style: TextStyle(color: AppColors.grey600),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(context, _orders[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final userId = SupabaseService().currentUser?.id;
    final isSale = order['seller_id'] == userId;
    final product = order['product'] as Map<String, dynamic>?;
    final counterpart = isSale
        ? order['buyer'] as Map<String, dynamic>?
        : order['seller'] as Map<String, dynamic>?;

    final grossAmount = (order['gross_amount'] as num?)?.toDouble() ?? 0;
    final visibleFee = (order['visible_fee'] as num?)?.toDouble() ?? 0;
    final netToSeller = (order['net_to_seller'] as num?)?.toDouble() ?? grossAmount;
    final amount = isSale ? netToSeller : grossAmount + visibleFee;

    final deliveryStatus = order['delivery_status'] as String? ?? 'none';
    final status = order['status'] as String? ?? 'pending';
    final isCod = order['payment_method'] == 'cash_on_delivery';
    // Ce que l'acheteur remettra en espèces au livreur : identique au total
    // affiché à la commande, frais de livraison compris.
    final codDue = grossAmount +
        visibleFee +
        ((order['delivery_fee'] as num?)?.toDouble() ?? 0);

    final statusColor = switch (status) {
      'success' => AppColors.success,
      'failed' => AppColors.error,
      _ => AppColors.warning,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSale ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSale ? Icons.arrow_downward : Icons.arrow_upward,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?['title'] as String? ?? 'Produit',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isSale
                          ? 'Vendu à ${counterpart?['full_name'] ?? 'un acheteur'}'
                          : 'Acheté à ${counterpart?['full_name'] ?? 'un vendeur'}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.grey600),
                    ),
                  ],
                ),
              ),
              Text(
                '${amount.toStringAsFixed(0)} FCFA',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSale ? AppColors.success : AppColors.error,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(_deliveryIcons[deliveryStatus] ?? Icons.help_outline,
                  size: 16, color: AppColors.grey600),
              const SizedBox(width: 6),
              Text(
                _deliveryLabels[deliveryStatus] ?? deliveryStatus,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.grey600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabels[status] ?? status,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          // Rappel du montant à prévoir tant que le livreur n'a pas encaissé :
          // c'est la seule commande où l'acheteur doit avoir des espèces prêtes.
          if (isCod && status == 'pending') ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isSale
                          ? 'Paiement à la livraison : vous serez crédité une fois le colis encaissé.'
                          : 'À payer en espèces au livreur : ${codDue.toStringAsFixed(0)} FCFA',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey900,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
