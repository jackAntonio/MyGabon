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
import 'providers/monetization_provider.dart';
import 'providers/analytics_provider.dart';

import 'config/theme.dart';

import 'services/notification_service.dart';
import 'services/geolocation_service.dart';
import 'services/cache_service.dart';
import 'services/connectivity_service.dart';
import 'services/offline_queue_service.dart';
import 'services/verification_service.dart';
import 'services/review_service.dart';
import 'services/fraud_detection_service.dart';
import 'services/supabase_service.dart';
import 'services/monetization_service.dart';
import 'services/analytics_service.dart';

import 'widgets/connection_widgets.dart';
import 'app_services.dart';

// Secrets injectés au build via --dart-define-from-file=env.json
// (jamais via un .env empaqueté comme asset, lisible en dézippant l'APK/IPA).
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
// ⚠️ Aucune clé Kpay ni Twilio ici (KPAY_API_KEY/KPAY_SECRET_KEY/
// KPAY_WEBHOOK_SECRET, TWILIO_ACCOUNT_SID/TWILIO_AUTH_TOKEN) : un APK/IPA
// est extractible, donc un secret ne doit JAMAIS être compilé dans l'app.
// Ces credentials vivent uniquement comme secrets des Edge Functions
// kpay-initiate / kpay-webhook / send-otp-sms (`supabase secrets set ...`),
// jamais côté client — cf. supabase/functions/kpay-initiate/index.ts et
// supabase/functions/send-otp-sms/index.ts.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    throw Exception(
      'SUPABASE_URL / SUPABASE_ANON_KEY manquants. '
      'Lancez avec --dart-define-from-file=env.json (voir env.json.example).',
    );
  }

  // Initialiser Supabase (backend principal : auth, base de données, RLS)
  await SupabaseService().init(url: _supabaseUrl, anonKey: _supabaseAnonKey);

  // Initialiser AppServices (HTTP client, notifications, audit log)
  await AppServices().init();

  // Initialize cache
  await CacheService.init();

  // Initialize security services
  await VerificationService().init();
  await FraudDetectionService().init();

  // Initialize monetization & analytics services
  await SubscriptionService().init();
  await FeaturedListingService().init();
  await RevenuePaymentService().init();
  await AnalyticsService().init();

  runApp(const GabonConnectApp());
}

/// Root of the GabonConnect application.
/// Sets up MaterialApp with bottom navigation and responsive theme.
class GabonConnectApp extends StatefulWidget {
  const GabonConnectApp({super.key});

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
        ChangeNotifierProvider(
            create: (_) => VerificationProvider(VerificationService())),
        ChangeNotifierProvider(create: (_) => ReviewProvider(ReviewService())),
        ChangeNotifierProvider(
            create: (_) => FraudDetectionProvider(FraudDetectionService())),
        // Monétisation & analytics (abonnement Pro, annonces en vedette, revenus)
        ChangeNotifierProvider(
            create: (_) => SubscriptionProvider(SubscriptionService())),
        ChangeNotifierProvider(
            create: (_) => FeaturedListingProvider(FeaturedListingService())),
        ChangeNotifierProvider(
            create: (_) => PaymentProvider(RevenuePaymentService())),
        ChangeNotifierProvider(
            create: (_) => AnalyticsProvider(AnalyticsService())),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'MyGabon',
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
  const MainScaffold({super.key});

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
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTap,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
              NavigationDestination(icon: Icon(Icons.build), label: 'Services'),
              NavigationDestination(icon: Icon(Icons.add_box), label: 'Publier'),
              NavigationDestination(
                  icon: Icon(Icons.store), label: 'Marché'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}
