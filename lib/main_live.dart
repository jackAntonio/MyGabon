import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ REMPLACER avec tes vraies credentials Supabase!
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY');

  // Pour test local: utiliser données mockées
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true,
  ).catchError((e) {
    print('⚠️ Supabase init error: $e - Using mock data');
  });

  runApp(const GabonConnectLiveApp());
}

class GabonConnectLiveApp extends StatefulWidget {
  const GabonConnectLiveApp({Key? key}) : super(key: key);

  @override
  State<GabonConnectLiveApp> createState() => _GabonConnectLiveAppState();
}

class _GabonConnectLiveAppState extends State<GabonConnectLiveApp> {
  int _currentIndex = 0;
  late SupabaseClient supabase;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      final response = await supabase.from('users').select().limit(1);
      setState(() {
        isConnected = response.isNotEmpty;
      });
      print('✅ Supabase Connected! ${response.length} users');
    } catch (e) {
      print('❌ Supabase Error: $e');
      setState(() {
        isConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GabonConnect - LIVE',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B6E4F),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B6E4F),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('GabonConnect'),
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? 'LIVE' : 'OFFLINE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _buildPage(_currentIndex),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
            NavigationDestination(icon: Icon(Icons.build), label: 'Services'),
            NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'Produits'),
            NavigationDestination(icon: Icon(Icons.chat), label: 'Messages'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildServicesPage();
      case 2:
        return _buildProductsPage();
      case 3:
        return _buildMessagesPage();
      case 4:
        return _buildProfilePage();
      default:
        return _buildHomePage();
    }
  }

  // ===== HOME PAGE =====
  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0B6E4F),
                  const Color(0xFF0077B6),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GabonConnect',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Marketplace Gabon - LIVE DATA',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                if (!isConnected)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Supabase non connecté - mode offline',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Services en Direct',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildServicesStream(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== SERVICES PAGE =====
  Widget _buildServicesPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tous les Services',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildServicesStream(),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesStream() {
    return FutureBuilder(
      future: supabase.from('services').select().limit(10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Center(
            child: Text('Aucun service trouvé'),
          );
        }

        final services = snapshot.data as List;

        return ListView.builder(
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            service['title'] ?? 'Service',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          '${service['rating']}⭐',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service['description'] ?? '',
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${service['price']} FCFA',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0B6E4F),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Service: ${service['title']}'),
                              ),
                            );
                          },
                          child: const Text('Voir'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===== PRODUCTS PAGE =====
  Widget _buildProductsPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Marketplace',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder(
              future: supabase.from('products').select().limit(10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final products = snapshot.data as List? ?? [];

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['title'] ?? 'Produit',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product['description'] ?? '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${product['price']} FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B6E4F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===== MESSAGES PAGE =====
  Widget _buildMessagesPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Messages',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder(
              future: supabase.from('messages').select().limit(20),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data as List? ?? [];

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(msg['content'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===== PROFILE PAGE =====
  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profils',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder(
              future: supabase.from('users').select().limit(10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data as List? ?? [];

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['full_name'] ?? 'User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(user['email'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              user['verified'] == true ? '✅ Vérifié' : '❌ Non vérifié',
                              style: TextStyle(
                                color: user['verified'] == true ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
