import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/location_view_model.dart';
import 'view_models/locale_view_model.dart';
import 'view_models/map_style_view_model.dart';
import 'view_models/order_view_model.dart';
import 'view_models/region_view_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/suspended_account_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/app_lifecycle_service.dart';
import 'services/fcm_service.dart';

// Background message handler - must be top-level function
// MUST be registered BEFORE Firebase.initializeApp() for terminated app state
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  
  // CRITICAL: Register background handler BEFORE Firebase initialization
  // This ensures notifications work when app is terminated
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize Firebase (driver app needs Firebase configured)
  // Note: You'll need to add firebase_options.dart for driver app
  // Run: flutterfire configure --project=your-project-id
  try {
    await Firebase.initializeApp();
    
    // Initialize FCM service for push notifications
    await FCMService().initialize();
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    debugPrint('   FCM features will not work until Firebase is configured');
  }
  
  // Initialize app lifecycle service for handling calls across all app states
  await AppLifecycleService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => LocationViewModel()),
        ChangeNotifierProvider(create: (_) => OrderViewModel()),
        ChangeNotifierProvider(create: (_) => MapStyleViewModel()),
        ChangeNotifierProvider(create: (_) => RegionViewModel()),
      ],
      child: Consumer<LocaleViewModel>(
        builder: (context, localeViewModel, _) {
          return MaterialApp(
            title: 'Delivery Driver App',
            debugShowCheckedModeBanner: false,
            locale: localeViewModel.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.lightTheme,
            navigatorKey: GlobalNavigatorKey.navigatorKey,
            routes: {
              '/home': (context) => const HomeScreen(),
              '/suspended': (context) => const SuspendedAccountScreen(),
            },
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

// Global navigator key for navigation from API client
class GlobalNavigatorKey {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasCheckedFCMToken = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthViewModel, LocaleViewModel>(
      builder: (context, authViewModel, localeViewModel, _) {
        // Sync language preference when user data is available
        if (authViewModel.isAuthenticated && authViewModel.user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final preferredLanguage = authViewModel.user?['preferredLanguage'] as String?;
            localeViewModel.syncFromBackend(preferredLanguage);
          });
        }
        
        // Check and refresh FCM token if user is authenticated
        // This is critical after app reinstallation
        if (authViewModel.isAuthenticated && !authViewModel.isCheckingAuth && !_hasCheckedFCMToken) {
          _hasCheckedFCMToken = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            // Check if we need to refresh token
            final prefs = await SharedPreferences.getInstance();
            final needsRefresh = prefs.getBool('needs_fcm_token_refresh') ?? false;
            final pendingToken = prefs.getString('pending_fcm_token');
            
            if (needsRefresh || pendingToken != null) {
              debugPrint('🔄 App launch: Refreshing FCM token for authenticated user...');
              // Small delay to ensure Firebase is ready
              await Future.delayed(const Duration(milliseconds: 1000));
              await FCMService().savePendingToken();
            } else {
              // Even if no flag is set, verify token is synced
              // This handles the case where app was reinstalled but flag wasn't set
              debugPrint('🔍 App launch: Verifying FCM token is synced...');
              await Future.delayed(const Duration(milliseconds: 1000));
              final fcmService = FCMService();
              if (fcmService.hasToken) {
                // Token exists, ensure it's synced
                await fcmService.savePendingToken();
              } else {
                // No token, force refresh
                await fcmService.forceRefreshAndSyncToken();
              }
            }
          });
        }
        
        // Show loading indicator while checking auth status
        if (authViewModel.isCheckingAuth) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Check if account is suspended
        if (authViewModel.isAuthenticated && authViewModel.isSuspended) {
          return const SuspendedAccountScreen();
        }
        
        if (authViewModel.isAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
