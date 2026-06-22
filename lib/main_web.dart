import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/services_screen.dart';
import 'screens/post_announcement_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/profile_screen.dart';

import 'providers/service_provider.dart';
import 'providers/marketplace_provider.dart';
import 'providers/chat_provider.dart';

import 'utils/theme.dart';

import 'services/notification_service.dart';
import 'services/geolocation_service.dart';
import 'services/cache_service.dart';
import 'services/connectivity_service.dart';
import 'services/offline_queue_service.dart';

import 'widgets/connection_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cache
  await CacheService.init();

  runApp(const GabonConnectApp());
}

/// Root of the GabonConnect application (Web version without Firebase).
class GabonConnectApp extends StatefulWidget {
  const GabonConnectApp({Key? key}) : super(key: key);

  @override
  State<GabonConnectApp> createState() => _GabonConnectAppState();
}

class _GabonConnectAppState extends State<GabonConnectApp> {
  final _connectivityService = ConnectivityService();
  final _offlineQueueService = OfflineQueueService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _offlineQueueService.init();

    _connectivityService.addListener(() {
      if (_connectivityService.isOnlineMode &&
          _offlineQueueService.getPendingActionCount() > 0) {
        debugPrint('🔄 Connexion restaurée, synchronisation des actions...');
        _offlineQueueService.syncAllPendingActions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    NotificationService().init();
    GeolocationService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _connectivityService),
        ChangeNotifierProvider.value(value: _offlineQueueService),
        ChangeNotifierProvider(
          create: (_) => ServiceProvider(_connectivityService),
        ),
        ChangeNotifierProvider(
          create: (_) => MarketplaceProvider(_connectivityService),
        ),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'GabonConnect',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainScaffold(),
        routes: {
          '/post': (context) => const PostAnnouncementScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    _offlineQueueService.dispose();
    super.dispose();
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
      body: Column(
        children: [
          const ConnectionStatusBanner(),
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTap,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.build), label: 'Services'),
              NavigationDestination(icon: Icon(Icons.add_box), label: 'Post'),
              NavigationDestination(
                  icon: Icon(Icons.store), label: 'Marketplace'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
