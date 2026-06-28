import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/marketplace_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/category_icon.dart';
import '../widgets/product_card.dart';
import 'services_screen.dart';
import 'marketplace_screen.dart';
import 'wallet_topup_screen.dart';

/// Accueil : salutation, recherche, catégories et offres à la une.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _opacity = 0;
  double? _walletBalance;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _opacity = 1);
    });
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return;
    final balance = await SupabaseService().getWalletBalance(userId);
    if (mounted) setState(() => _walletBalance = balance);
  }

  void _openServices({String? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServicesScreen(initialCategory: category),
      ),
    );
  }

  void _openMarketplace() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
    );
  }

  Future<void> _openWalletTopUp() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WalletTopUpScreen()),
    );
    _loadWalletBalance();
  }

  /// Salutation adaptée à l'heure de la journée.
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  Future<void> _refresh(MarketplaceProvider marketplace) async {
    await Future.wait([
      _loadWalletBalance(),
      marketplace.refreshProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final marketplace = Provider.of<MarketplaceProvider>(context);
    final firstName = auth.displayName.split(' ').first;

    return SafeArea(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 600),
        opacity: _opacity,
        child: RefreshIndicator(
          onRefresh: () => _refresh(marketplace),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                '${_greeting()}, $firstName 👋',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Que recherchez-vous aujourd\'hui ?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey600,
                    ),
              ),
              const SizedBox(height: 16),

              // Barre de recherche -> ouvre les services
              GestureDetector(
                onTap: () => _openServices(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.grey500),
                        SizedBox(width: 12),
                        Text(
                          'Rechercher un service ou un produit',
                          style: TextStyle(color: AppColors.grey500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Solde du portefeuille
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.darkBg],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Solde MyGabon Wallet',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          _walletBalance == null
                              ? '...'
                              : '${_walletBalance!.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: _openWalletTopUp,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Recharger'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Catégories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    CategoryIcon(
                      icon: Icons.bolt,
                      label: 'Électricité',
                      onTap: () => _openServices(category: 'Électricité'),
                    ),
                    const SizedBox(width: 16),
                    CategoryIcon(
                      icon: Icons.computer,
                      label: 'Informatique',
                      onTap: () => _openServices(category: 'Informatique'),
                    ),
                    const SizedBox(width: 16),
                    CategoryIcon(
                      icon: Icons.cleaning_services,
                      label: 'Nettoyage',
                      onTap: () => _openServices(category: 'Nettoyage'),
                    ),
                    const SizedBox(width: 16),
                    CategoryIcon(
                      icon: Icons.handyman,
                      label: 'Menuiserie',
                      onTap: () => _openServices(category: 'Menuiserie'),
                    ),
                    const SizedBox(width: 16),
                    CategoryIcon(
                      icon: Icons.store,
                      label: 'Marché',
                      onTap: _openMarketplace,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Offres à la une',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: _openMarketplace,
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: marketplace.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : marketplace.products.isEmpty
                        ? Center(
                            child: Text(
                              'Aucune offre pour le moment',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.grey500,
                                  ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: marketplace.products.length.clamp(0, 5),
                            itemBuilder: (context, index) {
                              return SizedBox(
                                width: 160,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: ProductCard(
                                      product: marketplace.products[index]),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
