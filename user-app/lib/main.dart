import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:delivery_user_app/firebase_options.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/order_view_model.dart';
import 'view_models/location_view_model.dart';
import 'view_models/locale_view_model.dart';
import 'view_models/map_style_view_model.dart';
import 'view_models/driver_view_model.dart';
import 'view_models/region_view_model.dart';
import 'screens/home/home_screen.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'services/app_lifecycle_service.dart';

/// Top-level function to handle background messages
/// MUST be registered BEFORE Firebase.initializeApp() for terminated app state
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  if (kDebugMode) {
    print('📨 Background message received: ${message.messageId}');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');
  }
  
  // Initialize local notifications plugin for background handler
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  
  // Initialize Android settings
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  await localNotifications.initialize(initSettings);
  
  // Create notification channel for Android
  const androidChannel = AndroidNotificationChannel(
    'order_updates',
    'Order Updates',
    description: 'Notifications for order status updates',
    importance: Importance.high,
    playSound: true,
  );
  
  await localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);
  
  // Show local notification if notification payload exists
  if (message.notification != null) {
    final notification = message.notification!;
    final title = notification.title ?? 'Order Update';
    final body = notification.body ?? '';
    
    const androidDetails = AndroidNotificationDetails(
      'order_updates',
      'Order Updates',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Create payload string from data
    String? payload;
    if (message.data['orderId'] != null) {
      payload = 'orderId=${message.data['orderId']}';
    }
    
    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
    
    if (kDebugMode) {
      print('✅ Local notification shown in background handler');
    }
  }
  
  // Store notification data for when app opens
  if (message.data['type'] == 'order_status_update' && message.data['orderId'] != null) {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_order_navigation', message.data['orderId']!);
      if (kDebugMode) {
        print('✅ Stored order ID for navigation: ${message.data['orderId']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error storing notification data: $e');
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  
  // CRITICAL: Register background handler BEFORE Firebase initialization
  // This ensures notifications work when app is terminated
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  await NotificationService().initialize();
  
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
            title: 'Wassle',
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
            // Handle unknown routes gracefully
            onUnknownRoute: (settings) {
              // For unknown routes, return to home
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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasCheckedFCMToken = false;

  @override
  void initState() {
    super.initState();
    // Sync language preference from backend when user data is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLanguagePreference();
    });
  }

  void _syncLanguagePreference() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final localeViewModel = Provider.of<LocaleViewModel>(context, listen: false);
    
    if (authViewModel.isAuthenticated && authViewModel.user != null) {
      final preferredLanguage = authViewModel.user?['preferredLanguage'] as String?;
      localeViewModel.syncFromBackend(preferredLanguage);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync language preference when user data changes
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        // Sync language preference when user data is available
        if (authViewModel.isAuthenticated && authViewModel.user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final localeViewModel = Provider.of<LocaleViewModel>(context, listen: false);
            final preferredLanguage = authViewModel.user?['preferredLanguage'] as String?;
            localeViewModel.syncFromBackend(preferredLanguage);
          });
        }
        
        // CRITICAL: Always check and refresh FCM token if user is authenticated
        // This ensures token is synced on every app start, even after reinstallation
        // or when backend removed invalid token
        if (authViewModel.isAuthenticated && !_hasCheckedFCMToken) {
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
        
        // Allow unauthenticated access - users can use the app without login
        // Verification only happens when placing an order
        return const HomeScreen();
      },
    );
  }
}
