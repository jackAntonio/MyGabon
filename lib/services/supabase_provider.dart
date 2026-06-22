import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import 'supabase_service.dart';

// ========== AUTHENTICATION ==========
final authStateProvider = StreamProvider<bool>((ref) {
  return Stream.value(supabaseService.isAuthenticated);
});

final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  if (!supabaseService.isAuthenticated) return null;
  final userId = supabaseService.currentUser?.id;
  if (userId == null) return null;
  return supabaseService.getUserProfile(userId);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return supabaseService.isAuthenticated;
});

// ========== PRODUCTS / MARKETPLACE ==========
final productsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    final response = await supabaseService.getAllProducts();
    return response;
  } catch (e) {
    debugPrint('Error fetching products: $e');
    return [];
  }
});

final productsByCategoryProvider = FutureProvider.family<List<Product>, String>((ref, category) async {
  try {
    final response = await supabaseService.getProductsByCategory(category);
    return response;
  } catch (e) {
    debugPrint('Error fetching products by category: $e');
    return [];
  }
});

// ========== WALLET ==========
final userWalletProvider = FutureProvider<double>((ref) async {
  if (!supabaseService.isAuthenticated) return 0.0;
  final userId = supabaseService.currentUser?.id;
  if (userId == null) return 0.0;

  try {
    return await supabaseService.getWalletBalance(userId);
  } catch (e) {
    debugPrint('Error fetching wallet: $e');
    return 0.0;
  }
});

// ========== TRANSACTIONS ==========
final userTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  if (!supabaseService.isAuthenticated) return [];
  final userId = supabaseService.currentUser?.id;
  if (userId == null) return [];

  try {
    return await supabaseService.getUserTransactions(userId);
  } catch (e) {
    debugPrint('Error fetching transactions: $e');
    return [];
  }
});

// ========== REVIEWS ==========
final productReviewsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
    (ref, productId) async {
  try {
    return await supabaseService.getProductReviews(productId);
  } catch (e) {
    debugPrint('Error fetching reviews: $e');
    return [];
  }
});

// ========== SERVICES ==========
final servicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    return await supabaseService.getServices();
  } catch (e) {
    debugPrint('Error fetching services: $e');
    return [];
  }
});
