import 'package:flutter/material.dart';
import '../models/product_model.dart';

/// Card used for marketplace products.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          color: Colors.grey[300],
          child: const Icon(Icons.image),
        ),
        title: Text(product.name),
        subtitle: Text('${product.location}'),
        trailing: Text('${product.price} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: () {},
      ),
    );
  }
}
