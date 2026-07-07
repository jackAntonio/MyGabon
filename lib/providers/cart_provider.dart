import 'package:flutter/material.dart';
import '../models/product.dart';

/// Panier d'achats local. Chaque produit reste payé individuellement via
/// `PaymentMethodSelectionScreen`, qui gère déjà le double système MyGabon
/// Wallet + Airtel Money (le backend ne sait créer qu'une transaction par
/// produit — cf. `SupabaseService.createTransaction`).
class CartProvider extends ChangeNotifier {
  final Map<String, MapEntry<Product, int>> _items = {};

  List<MapEntry<Product, int>> get items => _items.values.toList();

  int get itemCount => _items.values.fold(0, (sum, e) => sum + e.value);

  double get totalPrice =>
      _items.values.fold(0.0, (sum, e) => sum + e.key.price * e.value);

  void addToCart(Product product) {
    final existing = _items[product.id];
    _items[product.id] = MapEntry(product, (existing?.value ?? 0) + 1);
    notifyListeners();
  }

  void removeOne(String productId) {
    final existing = _items[productId];
    if (existing == null) return;
    if (existing.value <= 1) {
      _items.remove(productId);
    } else {
      _items[productId] = MapEntry(existing.key, existing.value - 1);
    }
    notifyListeners();
  }

  void removeAll(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
