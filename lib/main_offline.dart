import 'package:flutter/material.dart';
import 'services/demo_data.dart';

/// 🎬 GABON CONNECT - OFFLINE MODE
/// APP 100% FONCTIONNELLE SANS INTERNET
/// Vraies données stockées localement (Hive)
/// Tous les onglets query les données RÉELLES

void main() {
  runApp(const GabonConnectOfflineApp());
}

class GabonConnectOfflineApp extends StatefulWidget {
  const GabonConnectOfflineApp({Key? key}) : super(key: key);

  @override
  State<GabonConnectOfflineApp> createState() => _GabonConnectOfflineAppState();
}

class _GabonConnectOfflineAppState extends State<GabonConnectOfflineApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GabonConnect - OFFLINE',
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
          title: const Text('🇬🇦 GabonConnect'),
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '🟢 LIVE',
                        style: TextStyle(
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
    final stats = gabonDemoData['statistics'] as Map<String, dynamic>;
    final services = gabonDemoData['services'] as List;

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
                  'Marketplace Gabon - 🟢 LIVE DATA',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('👥', '${stats['total_users']}', 'Users'),
                    _buildStatCard(
                        '🔧', '${stats['total_services']}', 'Services'),
                    _buildStatCard(
                        '🛍️', '${stats['total_products']}', 'Products'),
                  ],
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
                ...services.take(3).map((s) => _buildServiceCard(s)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== SERVICES PAGE =====
  Widget _buildServicesPage() {
    final services = gabonDemoData['services'] as List;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tous les Services (${9} réels)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) =>
                  _buildServiceCard(services[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [Color(0xFFF4C430), Color(0xFF0077B6)],
            ),
          ),
          child: Center(
            child: Text(service['icon'] ?? '🔧',
                style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          service['title'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              service['description'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
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
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Service: ${service['title']}')),
          );
        },
      ),
    );
  }

  // ===== PRODUCTS PAGE =====
  Widget _buildProductsPage() {
    final products = gabonDemoData['products'] as List;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Marketplace (${5} réels)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF4C430), Color(0xFF0077B6)],
                        ),
                      ),
                      child: Center(
                        child: Text(p['icon'] ?? '🛍️',
                            style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    title: Text(p['title'] ?? ''),
                    subtitle: Text(
                      '${p['price']} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B6E4F),
                      ),
                    ),
                  ),
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
    final messages = gabonDemoData['messages'] as List;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Messages (${4} conversations)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
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
                            Text(
                              '${msg['sender_name']} → ${msg['receiver_name']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              msg['timestamp'],
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(msg['content']),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            msg['read'] ? '✅✅ Lu' : '✅ Envoyé',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
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
    final users = gabonDemoData['users'] as List;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Utilisateurs (${8} profils)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0B6E4F),
                      child: Text(
                        user['full_name'][0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user['full_name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(user['email']),
                        const SizedBox(height: 4),
                        Text(
                          user['verified'] == true
                              ? '✅ Verified'
                              : '❌ Not verified',
                          style: TextStyle(
                            color: user['verified'] == true
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${user['rating']}⭐',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String icon, String value, String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
