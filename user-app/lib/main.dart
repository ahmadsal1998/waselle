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
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/notification_service.dart';
import 'services/app_lifecycle_service.dart';

/// Top-level function to handle background messages
/// MUST be registered BEFORE Firebase.initializeApp() for terminated app state
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print('📨 Background message received: ${message.messageId}');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
  
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
    
    print('✅ Local notification shown in background handler');
  }
  
  // Store notification data for when app opens
  if (message.data['type'] == 'order_status_update' && message.data['orderId'] != null) {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_order_navigation', message.data['orderId']!);
      print('✅ Stored order ID for navigation: ${message.data['orderId']}');
    } catch (e) {
      print('❌ Error storing notification data: $e');
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Allow unauthenticated access - users can use the app without login
    // Verification only happens when placing an order
    return const HomeScreen();
  }
}
