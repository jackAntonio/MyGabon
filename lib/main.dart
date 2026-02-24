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
import 'providers/verification_provider.dart';
import 'providers/review_provider.dart';
import 'providers/fraud_detection_provider.dart';

import 'utils/theme.dart';

import 'services/notification_service.dart';
import 'services/geolocation_service.dart';
import 'services/cache_service.dart';
import 'services/connectivity_service.dart';
import 'services/offline_queue_service.dart';
import 'services/verification_service.dart';
import 'services/review_service.dart';
import 'services/fraud_detection_service.dart';

import 'widgets/connection_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cache
  await CacheService.init();
  
  // Initialize security services
  await VerificationService().init();
  await ReviewService().init();
  await FraudDetectionService().init();
  
  runApp(const GabonConnectApp());
}

/// Root of the GabonConnect application.
/// Sets up MaterialApp with bottom navigation and responsive theme.
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
  
  /// Initialize offline queue and sync when connection returns
  Future<void> _initializeServices() async {
    await _offlineQueueService.init();
    
    // Listen to connectivity changes and auto-sync when online
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
    // initialize services once
    NotificationService().init();
    GeolocationService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _connectivityService),
        ChangeNotifierProvider.value(value: _offlineQueueService),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => ServiceProvider(_connectivityService),
        ),
        ChangeNotifierProvider(
          create: (_) => MarketplaceProvider(_connectivityService),
        ),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        // Security & verification providers
        ChangeNotifierProvider(create: (_) => VerificationProvider(VerificationService())),
        ChangeNotifierProvider(create: (_) => ReviewProvider(ReviewService())),
        ChangeNotifierProvider(create: (_) => FraudDetectionProvider(FraudDetectionService())),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'GabonConnect',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
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
          // Connection status banner
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
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4)),
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
              NavigationDestination(icon: Icon(Icons.store), label: 'Marketplace'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
