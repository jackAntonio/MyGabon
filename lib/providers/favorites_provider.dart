import 'package:flutter/material.dart';
import '../models/product.dart';

/// Liste locale des produits favoris de l'utilisateur.
class FavoritesProvider extends ChangeNotifier {
  final Map<String, Product> _favorites = {};

  List<Product> get favorites => _favorites.values.toList();

  bool isFavorite(String productId) => _favorites.containsKey(productId);

  void toggle(Product product) {
    if (_favorites.containsKey(product.id)) {
      _favorites.remove(product.id);
    } else {
      _favorites[product.id] = product;
    }
    notifyListeners();
  }
}
