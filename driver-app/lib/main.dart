import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:delivery_driver_app/firebase_options.dart';
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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  
  // CRITICAL: Register background handler BEFORE Firebase initialization
  // This ensures notifications work when app is terminated
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize FCM service for push notifications
    // CRITICAL: This is called on every app start to ensure FCM token is always available
    // Even if user is not logged in yet, token will be generated and stored for later sync
    await FCMService().initialize();
    
    // Start periodic token sync check (every hour)
    // This ensures token is synced even if initial sync failed
    // or if backend removed invalid token
    FCMService().periodicTokenSyncCheck();
    // Schedule periodic checks every hour
    Timer.periodic(const Duration(hours: 1), (_) {
      FCMService().periodicTokenSyncCheck();
    });
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
            title: 'Wassle Driver',
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
        
        // CRITICAL: Always check and refresh FCM token if user is authenticated
        // This ensures token is synced on every app start, even after reinstallation
        // or when backend removed invalid token
        if (authViewModel.isAuthenticated && !authViewModel.isCheckingAuth && !_hasCheckedFCMToken) {
          _hasCheckedFCMToken = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            debugPrint('🔍 App launch: Ensuring FCM token is synced for authenticated user...');
            
            // Small delay to ensure Firebase is ready
            await Future.delayed(const Duration(milliseconds: 1000));
            
            final fcmService = FCMService();
            
            // Always verify token is synced, regardless of flags
            // This handles cases where:
            // 1. App was reinstalled (token changed)
            // 2. Backend removed invalid token (needs new token)
            // 3. Token refresh happened while app was closed
            if (fcmService.hasToken) {
              // Token exists, ensure it's synced to backend
              debugPrint('✅ Token exists, verifying sync to backend...');
              await fcmService.savePendingToken();
            } else {
              // No token, force refresh and sync
              debugPrint('⚠️ No token found, forcing refresh...');
              await fcmService.forceRefreshAndSyncToken();
            }
            
            // Also check for pending tokens
            final prefs = await SharedPreferences.getInstance();
            final pendingToken = prefs.getString('pending_fcm_token');
            if (pendingToken != null) {
              debugPrint('📱 Found pending token, syncing...');
              await fcmService.savePendingToken();
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
