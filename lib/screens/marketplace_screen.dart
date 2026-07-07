import 'package:flutter/material.dart';
import '../widgets/product_card.dart';

/// Marketplace screen displaying a list of products for sale.
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/skeleton_loader.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarketplaceProvider>(context);

    return AppScaffold(
      appBar: AppBar(title: const Text('Marché')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2)),
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Rechercher un produit...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: provider.search,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: Icon(
                  provider.isSortedByDistance
                      ? Icons.near_me_rounded
                      : Icons.near_me_outlined,
                  size: 18,
                  color: provider.isSortedByDistance
                      ? AppColors.white
                      : AppColors.primary,
                ),
                label: Text(provider.isSortedByDistance
                    ? 'Triés par proximité'
                    : 'Trier par proximité'),
                backgroundColor: provider.isSortedByDistance
                    ? AppColors.primary
                    : null,
                labelStyle: TextStyle(
                  color: provider.isSortedByDistance
                      ? AppColors.white
                      : null,
                ),
                onPressed: () async {
                  final success = await provider.sortByDistance();
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Activez la localisation pour trier par proximité'),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return SkeletonLoader(
                          height: 180, borderRadius: BorderRadius.circular(16));
                    },
                  )
                : provider.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off,
                                size: 48, color: AppColors.grey400),
                            const SizedBox(height: 12),
                            const Text('Aucun produit trouvé',
                                style: TextStyle(color: AppColors.grey600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: provider.refreshProducts,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: provider.products.length,
                          itemBuilder: (context, index) {
                            return ProductCard(
                                product: provider.products[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
