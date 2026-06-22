import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/supabase_provider.dart';
import '../widgets/modern_card.dart';

/// Complete Services Screen with real data
class ServicesScreenComplete extends ConsumerStatefulWidget {
  const ServicesScreenComplete({Key? key}) : super(key: key);

  @override
  ConsumerState<ServicesScreenComplete> createState() =>
      _ServicesScreenCompleteState();
}

class _ServicesScreenCompleteState
    extends ConsumerState<ServicesScreenComplete> {
  String _selectedCategory = 'Tous';
  final List<String> categories = [
    'Tous',
    'Électricité',
    'Nettoyage',
    'Informatique',
    'Menuiserie',
    'Beauté',
  ];

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services Gabon'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.accent.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Services Professionnels',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${9} services disponibles au Gabon',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey600,
                        ),
                  ),
                ],
              ),
            ),

            // Category filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: categories
                    .map((category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              setState(() => _selectedCategory =
                                  selected ? category : 'Tous');
                            },
                            backgroundColor: AppColors.white,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: _selectedCategory == category
                                  ? AppColors.white
                                  : AppColors.grey900,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: _selectedCategory == category
                                    ? AppColors.primary
                                    : AppColors.grey300,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            // Services list
            Padding(
              padding: const EdgeInsets.all(24),
              child: services.when(
                loading: () => _buildLoadingGrid(),
                error: (err, stack) => _buildErrorWidget(err.toString()),
                data: (servicesList) => _buildServicesList(servicesList),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ModernCard(
        title: '',
        description: '',
        price: '',
        rating: 0,
        sellerName: '',
        isLoading: true,
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Erreur: $error'),
        ],
      ),
    );
  }

  Widget _buildServicesList(List services) {
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined,
                size: 48, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'Aucun service trouvé',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return ModernCard(
          title: service['title'] ?? 'Service',
          description: service['description'] ?? '',
          price: '${service['price'] ?? 0} FCFA',
          rating: (service['rating'] as num?)?.toDouble() ?? 0.0,
          sellerName: service['provider']?['full_name'] ?? 'Provider',
          sellerAvatar: service['provider']?['avatar_url'],
          onTap: () {
            // Open service details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Service: ${service['title']}')),
            );
          },
        );
      },
    );
  }
}
