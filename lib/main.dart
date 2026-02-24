import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/services_screen.dart';
import 'screens/post_announcement_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const GabonConnectApp());
}

/// Root of the GabonConnect application.
/// Sets up MaterialApp with bottom navigation and responsive theme.
class GabonConnectApp extends StatelessWidget {
  const GabonConnectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GabonConnect',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MainScaffold(),
      routes: {
        '/post': (context) => const PostAnnouncementScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Main scaffold with a [BottomNavigationBar] to switch between screens.
class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    ServicesScreen(),
    MarketplaceScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.build), label: 'Services'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Marketplace'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/post');
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
