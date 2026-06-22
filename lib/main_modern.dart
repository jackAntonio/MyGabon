import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'screens/marketplace_detail_screen.dart';
import 'screens/auth_screen.dart';
import 'models/product.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/modern_card.dart';
import 'services/kpay_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger les variables d'environnement
  await dotenv.load();

  // Initialiser Supabase
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ??
          'https://kbggddignhydzxjzdera.supabase.com',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ??
          'sb_publishable_fb4ZPkQfXIXsh5jFWptcPA_TD8oIAUD',
      debug: false,
    );
    debugPrint('✅ Supabase initialisé');
  } catch (e) {
    debugPrint('❌ Erreur Supabase: $e');
  }

  // Initialiser Kpay pour paiements Airtel Money
  try {
    final kpayApiKey = dotenv.env['KPAY_API_KEY'];
    final kpayMerchantId = dotenv.env['KPAY_MERCHANT_ID'];

    if (kpayApiKey != null && kpayMerchantId != null) {
      _initKpay(kpayApiKey, kpayMerchantId);
      debugPrint('✅ Kpay initialisé');
    } else {
      debugPrint('⚠️ Kpay credentials non trouvés - mode simulation');
    }
  } catch (e) {
    debugPrint('❌ Erreur Kpay: $e');
  }

  runApp(
    const ProviderScope(
      child: GabonConnectModernApp(),
    ),
  );
}

void _initKpay(String apiKey, String merchantId) {
  // Import will be done at the top
  final kpay = KpayService();
  kpay.init(
    apiKey: apiKey,
    merchantId: merchantId,
    webhookSecret: dotenv.env['KPAY_WEBHOOK_SECRET'],
  );
}

class GabonConnectModernApp extends StatelessWidget {
  const GabonConnectModernApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyGabon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
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
    // Vérifier l'authentification
    final authState = Supabase.instance.client.auth.onAuthStateChange;

    return StreamBuilder(
      stream: authState,
      builder: (context, snapshot) {
        final isAuthenticated = snapshot.data?.session != null;

        if (!isAuthenticated) {
          return const AuthScreen();
        }

        return Scaffold(
          extendBody: true,
          body: _buildCurrentPage(),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
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
      },
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const HomeScreen(key: PageStorageKey('home'));
      case 1:
        return const ServicesScreen(key: PageStorageKey('services'));
      case 2:
        return const PostScreen(key: PageStorageKey('post'));
      case 3:
        return const MarketplaceScreen(key: PageStorageKey('marketplace'));
      case 4:
        return const ProfileScreen(key: PageStorageKey('profile'));
      default:
        return const HomeScreen(key: PageStorageKey('home'));
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
                  AppColors.primary.withValues(alpha: 0.7),
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
                        color: AppColors.white.withValues(alpha: 0.9),
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
      const MapEntry('Électronique', Icons.smartphone),
      const MapEntry('Vêtements', Icons.shopping_bag),
      const MapEntry('Maison', Icons.home),
      const MapEntry('Services', Icons.build),
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
                    category.value,
                    size: 18,
                  ),
                  label: Text(category.key),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({Key? key}) : super(key: key);

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final services = [
    {
      'title': '⚡ Installation électrique',
      'provider': 'Jean Mbadinga',
      'price': '50 000',
      'rating': 4.8
    },
    {
      'title': '⚡ Réparation électrique',
      'provider': 'Jean Mbadinga',
      'price': '25 000',
      'rating': 4.9
    },
    {
      'title': '🏡 Nettoyage maison',
      'provider': 'Marie Ondoua',
      'price': '30 000',
      'rating': 4.9
    },
    {
      'title': '🏢 Nettoyage bureau',
      'provider': 'Marie Ondoua',
      'price': '45 000',
      'rating': 4.7
    },
    {
      'title': '💻 Réparation ordinateur',
      'provider': 'Claude Nkomo',
      'price': '25 000',
      'rating': 4.7
    },
    {
      'title': '🌐 Installation réseau',
      'provider': 'Claude Nkomo',
      'price': '75 000',
      'rating': 4.8
    },
    {
      'title': '🪑 Menuiserie custom',
      'provider': 'Pierre Mboumbou',
      'price': '60 000',
      'rating': 4.6
    },
    {
      'title': '💅 Coiffure femme',
      'provider': 'Fatima Traoré',
      'price': '15 000',
      'rating': 4.9
    },
    {
      'title': '💈 Coiffure homme',
      'provider': 'Fatima Traoré',
      'price': '8 000',
      'rating': 4.8
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services Gabon'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Tous les Services (9)',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          ...services
              .map(
                (service) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(service['title']?.toString() ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(service['provider']?.toString() ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          '${service['price']} FCFA • ⭐ ${service['rating']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B6E4F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}

// ===== POST SCREEN =====
class PostScreen extends StatefulWidget {
  const PostScreen({Key? key}) : super(key: key);

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _category = 'Électronique';
  String _condition = 'Bon état';
  double _price = 0;
  int _quantity = 1;
  String _location = 'Libreville';
  bool _published = false;

  final categories = [
    'Électronique',
    'Vêtements',
    'Maison',
    'Services',
    'Autre'
  ];
  final conditions = ['Neuf', 'Bon état', 'Usé', 'À rénover'];
  final locations = [
    'Libreville',
    'Port-Gentil',
    'Franceville',
    'Oyem',
    'Bitam'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poster une annonce'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              Text('Titre', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Ex: iPhone 14 Pro',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => setState(() => _title = value),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Veuillez entrer un titre' : null,
              ),
              const SizedBox(height: 20),

              // Description field
              Text('Description',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Décrivez votre produit...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => setState(() => _description = value),
              ),
              const SizedBox(height: 20),

              // Category dropdown
              Text('Catégorie', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value ?? ''),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Condition dropdown
              Text('État', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _condition,
                items: conditions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _condition = value ?? ''),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Price field
              Text('Prix (FCFA)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) =>
                    setState(() => _price = double.tryParse(value) ?? 0),
              ),
              const SizedBox(height: 20),

              // Quantity
              Text('Quantité', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(
                        () => _quantity = (_quantity - 1).clamp(1, 999)),
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: TextFormField(
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      initialValue: _quantity.toString(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _quantity = int.tryParse(value) ?? 1),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(
                        () => _quantity = (_quantity + 1).clamp(1, 999)),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Location dropdown
              Text('Localisation',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _location,
                items: locations
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (value) => setState(() => _location = value ?? ''),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Publish toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Publier l\'annonce',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Visible immédiatement',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey600,
                                  ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _published,
                      activeThumbColor: AppColors.primary,
                      onChanged: (value) => setState(() => _published = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Annonce postée: $_title (${_price.toStringAsFixed(0)} FCFA)',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    'Publier l\'annonce',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.white,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
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
        title: 'Laptop Gaming RTX 4080',
        description: 'Ordinateur gaming haute performance',
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
      Product(
        id: '3',
        title: 'Canapé confortable 3 places',
        description: 'Canapé gris anthracite très confortable',
        price: 250000,
        category: 'Maison',
        imageUrl: null,
        sellerId: 'seller_3',
        sellerName: 'Marie Ondoua',
        sellerRating: 4.9,
        condition: 'Bon état',
        location: 'Libreville',
        createdAt: DateTime.now(),
        quantity: 1,
        published: true,
      ),
      Product(
        id: '4',
        title: 'Robe élégante taille M',
        description: 'Robe de soirée noire, jamais portée',
        price: 45000,
        category: 'Vêtements',
        imageUrl: null,
        sellerId: 'seller_4',
        sellerName: 'Fatima Traoré',
        sellerRating: 4.6,
        condition: 'Neuf',
        location: 'Franceville',
        createdAt: DateTime.now(),
        quantity: 2,
        published: true,
      ),
      Product(
        id: '5',
        title: 'Service d\'installation électrique',
        description: 'Installation électrique pour maison/bureau',
        price: 50000,
        category: 'Services',
        imageUrl: null,
        sellerId: 'seller_5',
        sellerName: 'Jean Mbadinga',
        sellerRating: 4.8,
        condition: 'Bon état',
        location: 'Libreville',
        createdAt: DateTime.now(),
        quantity: 5,
        published: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Tous les articles (5)',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          ...products
              .map((product) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MarketplaceDetailScreen(
                            product: product,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ModernCard(
                        title: product.title,
                        description: product.description,
                        price: product.formattedPrice,
                        rating: product.sellerRating,
                        sellerName: product.sellerName,
                      ),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}

// ===== PROFILE SCREEN =====
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final transactions = [
      {
        'date': '22 Jun 2026',
        'type': 'Achat',
        'amount': '850 000',
        'status': 'Réussi'
      },
      {
        'date': '20 Jun 2026',
        'type': 'Vente',
        'amount': '425 000',
        'status': 'Réussi'
      },
      {
        'date': '18 Jun 2026',
        'type': 'Achat',
        'amount': '120 000',
        'status': 'Réussi'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.white,
                    child: Text(
                      'AC',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Alice Cameroon',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'acaméron@example.com',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.accent, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '4.8 • 28 avis',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.white.withValues(alpha: 0.9),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Wallet section
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portefeuille MyGabon',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '485 750 FCFA',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add),
                          label: const Text('Recharger'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.send),
                          label: const Text('Envoyer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.white.withValues(alpha: 0.2),
                            foregroundColor: AppColors.white,
                            side: BorderSide(
                              color: AppColors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Transactions section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Historique des transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            ...transactions
                .map(
                  (tx) => Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx['type'] ?? '',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tx['date'] ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.grey600,
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${tx['amount']} FCFA',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tx['status'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),

            // Settings section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paramètres',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    context,
                    icon: Icons.edit,
                    title: 'Éditer le profil',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.lock,
                    title: 'Modifier le mot de passe',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.help,
                    title: 'Aide et support',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.logout,
                    title: 'Déconnexion',
                    onTap: () {},
                    isDangerous: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDangerous = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isDangerous ? AppColors.error : AppColors.primary,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isDangerous ? AppColors.error : null,
              ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.grey400,
        ),
      ),
    );
  }
}
