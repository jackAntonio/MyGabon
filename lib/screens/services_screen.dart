import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/service_provider.dart';
import '../widgets/service_card.dart';
import '../widgets/skeleton_loader.dart';

/// Écran des services proposés par les prestataires gabonais.
class ServicesScreen extends StatefulWidget {
  final String? initialCategory;

  const ServicesScreen({super.key, this.initialCategory});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late String _selectedCategory = widget.initialCategory ?? 'Tous';
  final List<String> _categories = const [
    'Tous',
    'Électricité',
    'Nettoyage',
    'Informatique',
    'Menuiserie',
    'Beauté',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ServiceProvider>().filterByCategory(widget.initialCategory!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ServiceProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: RefreshIndicator(
        onRefresh: provider.refreshServices,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                      'Services près de chez vous',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Électriciens, ménage, informatique et bien plus, partout au Gabon',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
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
                          hintText: 'Rechercher un service...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: provider.search,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
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
                            : AppColors.white,
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
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  children: _categories
                      .map((category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (selected) {
                                setState(() => _selectedCategory =
                                    selected ? category : 'Tous');
                                if (category == 'Tous') {
                                  provider.clearFilters();
                                } else {
                                  provider.filterByCategory(category);
                                }
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
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: provider.isLoading
                  ? SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => SkeletonLoader(
                            height: 220, borderRadius: BorderRadius.circular(20)),
                        childCount: 6,
                      ),
                    )
                  : provider.services.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.search_off,
                                      size: 48, color: AppColors.grey400),
                                  const SizedBox(height: 12),
                                  const Text('Aucun service trouvé',
                                      style: TextStyle(color: AppColors.grey600)),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                ServiceCard(service: provider.services[index]),
                            childCount: provider.services.length,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
