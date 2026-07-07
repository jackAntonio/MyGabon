import 'package:flutter/material.dart';
import '../widgets/product_card.dart';

/// Marketplace screen displaying a list of products for sale.
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/skeleton_loader.dart';
import 'post_announcement_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarketplaceProvider>(context);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Marché'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Publier une annonce',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostAnnouncementScreen()),
              );
              if (context.mounted) {
                provider.refreshProducts();
              }
            },
          ),
        ],
      ),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
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
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: provider.hasActiveFilters
                          ? AppColors.white
                          : AppColors.primary,
                    ),
                    label: const Text('Filtres'),
                    backgroundColor:
                        provider.hasActiveFilters ? AppColors.primary : null,
                    labelStyle: TextStyle(
                      color: provider.hasActiveFilters ? AppColors.white : null,
                    ),
                    onPressed: () => _openFilterSheet(context, provider),
                  ),
                ],
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

  static const _categories = [
    'Électronique',
    'Mode',
    'Maison & Jardin',
    'Véhicules',
    'Immobilier',
    'Meubles',
    'Autres',
  ];

  void _openFilterSheet(BuildContext context, MarketplaceProvider provider) {
    String? selectedCategory = provider.selectedCategory;
    final minController =
        TextEditingController(text: provider.minPrice?.toStringAsFixed(0) ?? '');
    final maxController =
        TextEditingController(text: provider.maxPrice?.toStringAsFixed(0) ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtres', style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text('Catégorie', style: Theme.of(sheetContext).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Toutes'),
                    selected: selectedCategory == null,
                    onSelected: (_) => setSheetState(() => selectedCategory = null),
                  ),
                  for (final category in _categories)
                    ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (_) =>
                          setSheetState(() => selectedCategory = category),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Prix (FCFA)', style: Theme.of(sheetContext).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        provider.clearFilters();
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      onPressed: () {
                        provider.filterByCategory(selectedCategory);
                        provider.filterByPrice(
                          double.tryParse(minController.text),
                          double.tryParse(maxController.text),
                        );
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Appliquer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
