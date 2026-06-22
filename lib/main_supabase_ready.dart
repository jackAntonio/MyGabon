import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🚀 GABON CONNECT - SUPABASE LIVE EDITION
/// App 100% fonctionnelle connectée à Supabase
/// Affiche VRAIES données en temps réel

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔧 Configuration Supabase (LOCAL ou CLOUD)
  const supabaseUrl = 'http://127.0.0.1:54321'; // LOCAL
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4YW1wbGUiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYxNTIwNjQwMCwiZXhwIjoxNzQzODQyNDAwfQ.rq7DrHzryFtWQ33dus7PAseIvUbtFsvu0ImCUEKsH3U';

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: false,
    );
    print('✅ Supabase Connected!');
  } catch (e) {
    print('⚠️ Supabase init error: $e');
  }

  runApp(const GabonConnectApp());
}

class GabonConnectApp extends StatefulWidget {
  const GabonConnectApp({Key? key}) : super(key: key);

  @override
  State<GabonConnectApp> createState() => _GabonConnectAppState();
}

class _GabonConnectAppState extends State<GabonConnectApp> {
  int _currentIndex = 0;
  bool isConnected = false;
  late SupabaseClient supabase;

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      final response = await supabase
          .from('users')
          .select('count(*)')
          .limit(1)
          .catchError((e) => throw e);

      setState(() => isConnected = true);
      print('✅ Database Connected! Data ready to load.');
    } catch (e) {
      print('❌ Connection Error: $e');
      setState(() => isConnected = false);
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
          title: const Text('🇬🇦 GabonConnect - LIVE'),
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? '🟢 LIVE' : '🟠 CONNECTING',
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
        body: isConnected ? _buildPage(_currentIndex) : _buildConnectionError(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
            NavigationDestination(icon: Icon(Icons.build), label: 'Services'),
            NavigationDestination(
                icon: Icon(Icons.shopping_bag), label: 'Produits'),
            NavigationDestination(icon: Icon(Icons.chat), label: 'Messages'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profils'),
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildConnectionError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Supabase non connecté',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Assurez-vous que Supabase est lancé:\nsupabase start',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _testConnection,
            child: const Text('Réessayer'),
          ),
        ],
      ),
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
        return _buildProfilesPage();
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B6E4F), Color(0xFF0077B6)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GabonConnect',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Marketplace Gabon - 🟢 LIVE DATA',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
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
                  'Services Populaires',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildServicesStreamPreview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesStreamPreview() {
    return FutureBuilder(
      future: supabase.from('services').select().limit(3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }

        final services = snapshot.data as List? ?? [];

        return Column(
          children:
              services.map((service) => _buildServiceCard(service)).toList(),
        );
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF4C430), Color(0xFF0077B6)],
                ),
              ),
              child: const Icon(Icons.build, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['title'] ?? 'Service',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service['description'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${service['price']} FCFA • ⭐ ${service['rating']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF0B6E4F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            child: FutureBuilder(
              future: supabase.from('services').select(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final services = snapshot.data as List? ?? [];

                return ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) =>
                      _buildServiceCard(services[index]),
                );
              },
            ),
          ),
        ],
      ),
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
              future: supabase.from('products').select(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data as List? ?? [];

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['title'] ?? 'Produit',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${p['price']} FCFA',
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
              future: supabase.from('messages').select(),
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
                      margin: const EdgeInsets.only(bottom: 12),
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

  // ===== PROFILES PAGE =====
  Widget _buildProfilesPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Utilisateurs',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder(
              future: supabase.from('users').select(),
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
                              user['verified'] == true
                                  ? '✅ Vérifié'
                                  : '❌ Non vérifié',
                              style: TextStyle(
                                color: user['verified'] == true
                                    ? Colors.green
                                    : Colors.red,
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
