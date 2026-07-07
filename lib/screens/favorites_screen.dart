import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/favorites_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>().favorites;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Mes favoris'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_border_rounded,
                      size: 64, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun favori pour le moment',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.grey600),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.62,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) =>
                  ProductCard(product: favorites[index]),
            ),
    );
  }
}
