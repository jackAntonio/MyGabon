import 'package:flutter/material.dart';

/// Grid of category tiles displayed on the home screen.
/// Catégories alignées sur celles proposées à la publication
/// (lib/screens/post_announcement_screen.dart) pour rester cohérentes
/// avec les valeurs réellement stockées dans `products.category`.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  static const List<String> categories = [
    'Électronique',
    'Mode',
    'Maison & Jardin',
    'Véhicules',
    'Immobilier',
    'Meubles',
    'Autres',
  ];

  @override
  Widget build(BuildContext context) {

    return GridView.builder(
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final name = categories[index];
        return GestureDetector(
          onTap: () {
            // navigate to filtered services
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(name, style: const TextStyle(fontSize: 16)),
          ),
        );
      },
    );
  }
}
