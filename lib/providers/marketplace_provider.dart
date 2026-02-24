import 'package:flutter/material.dart';
import '../models/product_model.dart';

/// Marketplace data provider with dummy products.
class MarketplaceProvider extends ChangeNotifier {
  List<ProductModel> _products = [];

  List<ProductModel> get products => _products;

  MarketplaceProvider() {
    _products = [
      ProductModel(name: 'Used Laptop', price: 2500000, location: 'Libreville'),
      ProductModel(name: 'Smartphone', price: 1200000, location: 'Port-Gentil'),
    ];
  }

  void search(String query) {
    // TODO: implement search
    notifyListeners();
  }
}
