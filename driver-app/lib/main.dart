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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
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
