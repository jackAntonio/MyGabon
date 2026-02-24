import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/services_screen.dart';
import 'screens/post_announcement_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

import 'providers/auth_provider.dart';
import 'providers/service_provider.dart';
import 'providers/marketplace_provider.dart';
import 'providers/chat_provider.dart';
import 'utils/theme.dart';
import 'services/notification_service.dart';
import 'services/geolocation_service.dart';

void main() {
  runApp(const GabonConnectApp());
}

/// Root of the GabonConnect application.
/// Sets up MaterialApp with bottom navigation and responsive theme.
class GabonConnectApp extends StatelessWidget {
  const GabonConnectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // initialize services once, log errors if any
    NotificationService().init();
    GeolocationService(); // constructor available for later use

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => MarketplaceProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'GabonConnect',
            theme: AppTheme.lightTheme,
            home: auth.isLoggedIn ? const MainScaffold() : const LoginScreen(),
            routes: {
              '/post': (context) => const PostAnnouncementScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
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
    PostAnnouncementScreen(),
    MarketplaceScreen(),
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
          NavigationDestination(icon: Icon(Icons.add_box), label: 'Post'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Marketplace'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
