import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

/// Initialize Supabase (call this in main)
Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://kbggddignhydzxjzdera.supabase.co',
    anonKey: 'sb_publishable_fb4ZPkQfXIXsh5jFWptcPA_TD8oIAUD',
  );
}

/// Supabase client provider
final supabaseProvider = Provider((ref) {
  return Supabase.instance.client;
});

/// Current authenticated user
final currentUserProvider = StreamProvider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange.map((data) => data.session?.user);
});

/// All products from marketplace
final productsProvider = FutureProvider((ref) async {
  final supabase = ref.watch(supabaseProvider);

  try {
    final response = await supabase
        .from('products')
        .select('''
          *,
          seller:seller_id (
            id,
            full_name,
            avatar_url
          )
        ''')
        .eq('published', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Product.fromJson(json))
        .toList();
  } catch (e) {
    throw Exception('Error fetching products: $e');
  }
});

/// All services
final servicesProvider = FutureProvider((ref) async {
  final supabase = ref.watch(supabaseProvider);

  try {
    final response = await supabase
        .from('services')
        .select('''
          *,
          provider:provider_id (
            id,
            full_name,
            avatar_url
          )
        ''')
        .eq('published', true)
        .order('rating', ascending: false);

    return response as List;
  } catch (e) {
    throw Exception('Error fetching services: $e');
  }
});

/// All users (sellers)
final usersProvider = FutureProvider((ref) async {
  final supabase = ref.watch(supabaseProvider);

  try {
    final response = await supabase
        .from('users')
        .select()
        .order('verified', ascending: false)
        .order('rating', ascending: false);

    return response as List;
  } catch (e) {
    throw Exception('Error fetching users: $e');
  }
});

/// Get specific product by ID
final productDetailProvider = FutureProvider.family((ref, String productId) async {
  final supabase = ref.watch(supabaseProvider);

  try {
    final response = await supabase
        .from('products')
        .select('''
          *,
          seller:seller_id (
            id,
            full_name,
            avatar_url,
            rating
          )
        ''')
        .eq('id', productId)
        .single();

    return Product.fromJson(response);
  } catch (e) {
    throw Exception('Error fetching product: $e');
  }
});

/// User wallet balance
final userWalletProvider = FutureProvider((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);

  return user.when(
    loading: () => 0.0,
    error: (err, stack) => 0.0,
    data: (userData) async {
      if (userData == null) return 0.0;

      try {
        final response = await supabase
            .from('user_wallets')
            .select('balance')
            .eq('user_id', userData.id)
            .single();

        return (response['balance'] as num).toDouble();
      } catch (e) {
        return 0.0;
      }
    },
  );
});

/// User profile with stats
final userProfileProvider = FutureProvider((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);

  return user.whenData((userData) {
    if (userData == null) return null;

    return supabase
        .from('users')
        .select('''
          *,
          orders_count:products(count),
          services_count:services(count)
        ''')
        .eq('id', userData.id)
        .single();
  });
});

/// Transaction history
final transactionHistoryProvider = FutureProvider((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);

  return user.whenData((userData) {
    if (userData == null) return [];

    return supabase
        .from('transactions')
        .select()
        .or('buyer_id.eq.${userData.id},seller_id.eq.${userData.id}')
        .order('created_at', ascending: false)
        .limit(20);
  });
});

/// Create new product listing
final createProductProvider = FutureProvider.family<String, Map<String, dynamic>>(
  (ref, productData) async {
    final supabase = ref.watch(supabaseProvider);
    final user = ref.watch(currentUserProvider);

    return user.whenData((userData) async {
      if (userData == null) throw Exception('Not authenticated');

      try {
        final response = await supabase
            .from('products')
            .insert({
              ...productData,
              'seller_id': userData.id,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        return response['id'] as String;
      } catch (e) {
        throw Exception('Error creating product: $e');
      }
    }).future;
  },
);

/// Charge user wallet for payment
final chargeWalletProvider = FutureProvider.family<bool, Map<String, dynamic>>(
  (ref, paymentData) async {
    final supabase = ref.watch(supabaseProvider);
    final user = ref.watch(currentUserProvider);

    return user.whenData((userData) async {
      if (userData == null) throw Exception('Not authenticated');

      try {
        await supabase.rpc(
          'deduct_wallet_and_log_transaction',
          params: {
            'p_buyer_id': userData.id,
            'p_seller_id': paymentData['seller_id'],
            'p_product_id': paymentData['product_id'],
            'p_amount': paymentData['amount'],
            'p_visible_fee': paymentData['visible_fee'],
            'p_actual_fee': paymentData['actual_fee'],
            'p_payment_method': 'myGabon',
          },
        );

        return true;
      } catch (e) {
        throw Exception('Error processing payment: $e');
      }
    }).future;
  },
);

/// Log Airtel Money payment
final logAirtelPaymentProvider = FutureProvider.family<bool, Map<String, dynamic>>(
  (ref, transactionData) async {
    final supabase = ref.watch(supabaseProvider);

    try {
      await supabase
          .from('transactions')
          .insert({
            ...transactionData,
            'payment_method': 'airtelMoney',
            'status': 'success',
            'created_at': DateTime.now().toIso8601String(),
          });

      return true;
    } catch (e) {
      throw Exception('Error logging Airtel payment: $e');
    }
  },
);

/// Sign up new user
final signUpProvider = FutureProvider.family<bool, Map<String, dynamic>>(
  (ref, credentials) async {
    final supabase = ref.watch(supabaseProvider);

    try {
      final response = await supabase.auth.signUp(
        email: credentials['email'] as String,
        password: credentials['password'] as String,
      );

      if (response.user != null) {
        // Create user profile
        await supabase.from('users').insert({
          'id': response.user!.id,
          'email': credentials['email'],
          'full_name': credentials['full_name'],
          'phone_number': credentials['phone_number'],
          'created_at': DateTime.now().toIso8601String(),
        });

        // Create wallet
        await supabase.from('user_wallets').insert({
          'user_id': response.user!.id,
          'balance': 0.0,
        });

        return true;
      }

      return false;
    } catch (e) {
      throw Exception('Error signing up: $e');
    }
  },
);

/// Sign in user
final signInProvider = FutureProvider.family<bool, Map<String, dynamic>>(
  (ref, credentials) async {
    final supabase = ref.watch(supabaseProvider);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: credentials['email'] as String,
        password: credentials['password'] as String,
      );

      return response.user != null;
    } catch (e) {
      throw Exception('Error signing in: $e');
    }
  },
);

/// Sign out
final signOutProvider = FutureProvider((ref) async {
  final supabase = ref.watch(supabaseProvider);
  await supabase.auth.signOut();
  return true;
});
