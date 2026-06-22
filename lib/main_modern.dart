import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'screens/marketplace_detail_screen.dart';
import 'models/product.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/modern_card.dart';

void main() {
  runApp(
    const ProviderScope(
      child: GabonConnectModernApp(),
    ),
  );
}

class GabonConnectModernApp extends StatelessWidget {
  const GabonConnectModernApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GabonConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<NavBarItem> navItems = [
    NavBarItem(icon: Icons.home_rounded, label: 'Accueil'),
    NavBarItem(icon: Icons.build_rounded, label: 'Services'),
    NavBarItem(icon: Icons.edit_rounded, label: 'Poster'),
    NavBarItem(icon: Icons.shopping_bag_rounded, label: 'Marketplace'),
    NavBarItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _buildCurrentPage(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Stack(
        children: [
          FloatingNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: navItems,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(key: PageStorageKey('home'));
      case 1:
        return ServicesScreen(key: PageStorageKey('services'));
      case 2:
        return PostScreen(key: PageStorageKey('post'));
      case 3:
        return MarketplaceScreen(key: PageStorageKey('marketplace'));
      case 4:
        return ProfileScreen(key: PageStorageKey('profile'));
      default:
        return HomeScreen(key: PageStorageKey('home'));
    }
  }
}

// ===== HOME SCREEN =====
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock products with real Gabon data
    final featuredProducts = [
      Product(
        id: '1',
        title: 'iPhone 14 Pro',
        description: 'Téléphone dernière génération en excellent état',
        price: 850000,
        category: 'Électronique',
        imageUrl: null,
        sellerId: 'seller_1',
        sellerName: 'Sophie Ivié',
        sellerRating: 4.8,
        condition: 'Neuf',
        location: 'Libreville',
        createdAt: DateTime.now(),
        quantity: 1,
        published: true,
      ),
      Product(
        id: '2',
        title: 'Laptop Gaming',
        description: 'Ordinateur gaming haute performance RTX 4080',
        price: 1200000,
        category: 'Électronique',
        imageUrl: null,
        sellerId: 'seller_2',
        sellerName: 'Claude Nkomo',
        sellerRating: 4.7,
        condition: 'Bon état',
        location: 'Port-Gentil',
        createdAt: DateTime.now(),
        quantity: 1,
        published: true,
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with glassmorphism
          Container(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: 32,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Découvrez les meilleures offres du Gabon',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),

          // Category chips
          _buildCategoryChips(context),

          // Featured section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Text(
              'Offres en vedette',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: featuredProducts.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarketplaceDetailScreen(
                        product: featuredProducts[index],
                      ),
                    ),
                  );
                },
                child: ModernCard(
                  title: featuredProducts[index].title,
                  description: featuredProducts[index].description,
                  price: featuredProducts[index].formattedPrice,
                  rating: featuredProducts[index].sellerRating,
                  sellerName: featuredProducts[index].sellerName,
                ),
              ),
            ),
          ),

          const SizedBox(height: 100), // Space for floating nav
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final categories = [
      ('Électronique', Icons.smartphones),
      ('Vêtements', Icons.shopping_bag),
      ('Maison', Icons.home),
      ('Services', Icons.build),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: categories
            .map(
              (category) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  avatar: Icon(
                    category.$2,
                    size: 18,
                  ),
                  label: Text(category.$1),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.primary),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ===== SERVICES SCREEN =====
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Services (À implémenter)',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

// ===== POST SCREEN =====
class PostScreen extends StatelessWidget {
  const PostScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Poster une annonce (À implémenter)',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

// ===== MARKETPLACE SCREEN =====
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final products = [
      Product(
        id: '1',
        title: 'iPhone 14 Pro',
        description: 'Téléphone dernière génération',
        price: 850000,
        category: 'Électronique',
        imageUrl: null,
        sellerId: 'seller_1',
        sellerName: 'Sophie Ivié',
        sellerRating: 4.8,
        condition: 'Neuf',
        location: 'Libreville',
        createdAt: DateTime.now(),
        quantity: 1,
        published: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: products.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarketplaceDetailScreen(
                  product: products[index],
                ),
              ),
            );
          },
          child: ModernCard(
            title: products[index].title,
            description: products[index].description,
            price: products[index].formattedPrice,
            rating: products[index].sellerRating,
            sellerName: products[index].sellerName,
          ),
        ),
      ),
    );
  }
}

// ===== PROFILE SCREEN =====
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Profil (À implémenter)',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
