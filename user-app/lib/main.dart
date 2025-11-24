import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/order_view_model.dart';
import 'view_models/location_view_model.dart';
import 'view_models/locale_view_model.dart';
import 'view_models/map_style_view_model.dart';
import 'view_models/driver_view_model.dart';
import 'view_models/region_view_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/app_lifecycle_service.dart';
import 'services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize FCM service for push notifications
  await FCMService().initialize();
  
  // Initialize app lifecycle service for handling calls across all app states
  final navigatorKey = GlobalNavigatorKey.navigatorKey;
  await AppLifecycleService().initialize(navigatorKey: navigatorKey);
  
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
        ChangeNotifierProvider(create: (_) => DriverViewModel()),
        ChangeNotifierProvider(create: (_) => RegionViewModel()),
      ],
      child: Consumer<LocaleViewModel>(
        builder: (context, localeViewModel, _) {
          return MaterialApp(
            title: 'Delivery User App',
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
            home: const AuthWrapper(),
            // Handle unknown routes (like Firebase Auth callbacks) gracefully
            onUnknownRoute: (settings) {
              // Firebase Auth callbacks use custom URL schemes - ignore them
              // They're handled natively by Firebase Auth, not by Flutter routing
              final uri = Uri.tryParse(settings.name ?? '');
              if (uri != null && 
                  (uri.scheme.startsWith('app-') || 
                   uri.scheme.contains('googleusercontent') ||
                   uri.scheme == 'com.googleusercontent.apps')) {
                // This is a Firebase Auth callback - return a dummy route that does nothing
                return MaterialPageRoute(
                  builder: (_) => const SizedBox.shrink(),
                  settings: settings,
                );
              }
              // For other unknown routes, return to home
              return MaterialPageRoute(
                builder: (_) => const AuthWrapper(),
                settings: settings,
              );
            },
          );
        },
      ),
    );
  }
}

// Global navigator key for navigation from anywhere in the app
class GlobalNavigatorKey {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Allow unauthenticated access - users can use the app without login
    // Verification only happens when placing an order
    return const HomeScreen();
  }
}
