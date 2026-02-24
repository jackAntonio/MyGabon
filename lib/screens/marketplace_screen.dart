import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';

/// Marketplace screen displaying a list of products for sale.
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  static final List<ProductModel> _products = [
    ProductModel(
      name: 'Used Laptop',
      price: 2500000,
      location: 'Libreville',
    ),
    ProductModel(
      name: 'Smartphone',
      price: 1200000,
      location: 'Port-Gentil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: _products[index]);
        },
      ),
    );
  }
}
