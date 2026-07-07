import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/payment_service.dart';
import '../widgets/app_scaffold.dart';
import 'payment/cart_checkout_screen.dart';
import 'payment/payment_method_selection_screen.dart';

/// Panier : chaque produit peut se payer individuellement (Airtel Money,
/// espèces, Apple/Google Pay) via "Payer cet article", ou tout le panier
/// en une fois via "Payer le panier" (MyGabon Wallet uniquement, RPC
/// complete_cart_checkout atomique côté serveur).
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Mon panier'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: cart.items.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _CartItemTile(entry: cart.items[index]),
            ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (${cart.itemCount} article${cart.itemCount > 1 ? 's' : ''})',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.grey600,
                            ),
                      ),
                      Text(
                        '${cart.totalPrice.toStringAsFixed(0)} FCFA',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CartCheckoutScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Payer le panier'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'Votre panier est vide',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final MapEntry<Product, int> entry;
  const _CartItemTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final product = entry.key;
    final qty = entry.value;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 56,
                  height: 56,
                  color: AppColors.grey100,
                  child: product.imageUrl != null
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.image_outlined,
                          color: AppColors.grey400),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.formattedPrice,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.grey600),
                onPressed: () =>
                    context.read<CartProvider>().removeOne(product.id),
              ),
              Text('$qty', style: Theme.of(context).textTheme.titleSmall),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: AppColors.primary),
                onPressed: () =>
                    context.read<CartProvider>().addToCart(product),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentMethodSelectionScreen(
                      product: product,
                      deliveryFee: PaymentService.standardDeliveryFee,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Payer cet article'),
            ),
          ),
        ],
      ),
    );
  }
}
