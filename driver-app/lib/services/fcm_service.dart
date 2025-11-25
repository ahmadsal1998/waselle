import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart';
import '../main.dart'; // For GlobalNavigatorKey

/// Firebase Cloud Messaging service for handling push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;
  bool _isInitialized = false;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ User granted provisional notification permission');
      } else {
        debugPrint('❌ User declined notification permission');
        return;
      }

      // Initialize local notifications for foreground notifications
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

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      const orderUpdatesChannel = AndroidNotificationChannel(
        'order_updates',
        'Order Updates',
        description: 'Notifications for order status updates',
        importance: Importance.high,
        playSound: true,
      );

      const incomingCallsChannel = AndroidNotificationChannel(
        'incoming_calls',
        'Incoming Calls',
        description: 'Notifications for incoming calls',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(orderUpdatesChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(incomingCallsChannel);

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        debugPrint('📱 FCM Token: ${_fcmToken!.substring(0, 20)}...');
        await _saveTokenToBackend(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM token refreshed: ${newToken.substring(0, 20)}...');
        _fcmToken = newToken;
        _saveTokenToBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message when app is opened from terminated state
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification (terminated state)
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📱 App opened from notification (terminated state)');
        // Wait a bit for app to initialize
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationTap(initialMessage);
        });
      }

      _isInitialized = true;
      debugPrint('✅ FCM Service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing FCM service: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 Foreground message received: ${message.messageId}');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    final notification = message.notification;
    final data = message.data;

    // Show local notification when app is in foreground
    String title = 'Order Update';
    String body = '';

    if (notification != null) {
      title = notification.title ?? title;
      body = notification.body ?? body;
    } else if (data['title'] != null) {
      title = data['title']!;
      body = data['body'] ?? '';
    }

    // Determine channel ID based on notification type
    String channelId = 'order_updates';
    if (data['type'] == 'incoming_call') {
      channelId = 'incoming_calls';
    }

    // Show notification if we have content
    if (body.isNotEmpty || title != 'Order Update') {
      await _showLocalNotification(
        title: title,
        body: body,
        data: data,
        channelId: channelId,
      );
      debugPrint('✅ Local notification shown in foreground');
    } else {
      debugPrint('⚠️ No notification content to display');
    }

    // Handle incoming call notification
    if (data['type'] == 'incoming_call') {
      _handleIncomingCallNotification(data);
    }
  }

  /// Handle notification tap (when user taps notification)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.messageId}');
    debugPrint('   Data: ${message.data}');

    final data = message.data;

    // Handle incoming call notification
    if (data['type'] == 'incoming_call') {
      _handleIncomingCallNotification(data);
    } else if (data['type'] == 'order_status_update' && data['orderId'] != null) {
      // Store order ID for navigation
      _storePendingNavigation(data['orderId']);
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Local notification tapped: ${response.id}');
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = Map<String, dynamic>.from(
          Uri.splitQueryString(payload),
        );
        if (data['orderId'] != null) {
          _storePendingNavigation(data['orderId']!);
        }
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String channelId = 'order_updates',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'incoming_calls' ? 'Incoming Calls' : 'Order Updates',
      channelDescription: channelId == 'incoming_calls'
          ? 'Notifications for incoming calls'
          : 'Notifications for order status updates',
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

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create payload string from data
    String? payload;
    if (data != null && data['orderId'] != null) {
      payload = 'orderId=${data['orderId']}';
    }

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle incoming call notification data
  void _handleIncomingCallNotification(Map<String, dynamic> data) {
    final orderId = data['orderId']?.toString();
    final roomId = data['roomId']?.toString();
    final callerId = data['callerId']?.toString();
    final callerName = data['callerName']?.toString() ?? 'Unknown';

    if (orderId == null || roomId == null || callerId == null) {
      debugPrint('❌ Invalid incoming call notification data');
      return;
    }

    debugPrint('📞 Handling incoming call from notification: $callerName');

    // Get context from global navigator key
    final context = GlobalNavigatorKey.navigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ No context available, storing call for later');
      // Store call data for later handling
      _storePendingCall(orderId, roomId, callerId, callerName);
      return;
    }

    // Call functionality removed - ZegoUIKitPrebuiltCall dependency removed
    // Incoming call handling disabled
  }

  /// Store pending call for later handling
  Future<void> _storePendingCall(
    String orderId,
    String roomId,
    String callerId,
    String callerName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_call_from_notification',
        '$orderId|$roomId|$callerId|$callerName');
      debugPrint('💾 Stored pending call from notification');
    } catch (e) {
      debugPrint('Error storing pending call: $e');
    }
  }

  /// Store pending navigation order ID
  void _storePendingNavigation(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_order_navigation', orderId);
      debugPrint('💾 Stored pending order navigation: $orderId');
    } catch (e) {
      debugPrint('❌ Error storing pending navigation: $e');
    }
  }

  /// Save FCM token to backend
  Future<void> _saveTokenToBackend(String token) async {
    try {
      await ApiClient.post('/users/fcm-token', body: {'fcmToken': token});
      debugPrint('✅ FCM token saved to backend');
    } catch (e) {
      debugPrint('❌ Error saving FCM token to backend: $e');
    }
  }

  /// Get current FCM token
  String? get token => _fcmToken;

  /// Check if FCM is initialized
  bool get isInitialized => _isInitialized;
}

/// Top-level function for handling background messages
/// This must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate
  // Note: If firebase_options.dart exists, use: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Otherwise, Firebase will use platform-specific config files (GoogleService-Info.plist for iOS, google-services.json for Android)
  await Firebase.initializeApp();
  
  debugPrint('📨 Background message received: ${message.messageId}');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');
  
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
  
  // Create notification channels for Android
  const orderUpdatesChannel = AndroidNotificationChannel(
    'order_updates',
    'Order Updates',
    description: 'Notifications for order status updates',
    importance: Importance.high,
    playSound: true,
  );
  
  const incomingCallsChannel = AndroidNotificationChannel(
    'incoming_calls',
    'Incoming Calls',
    description: 'Notifications for incoming calls',
    importance: Importance.high,
    playSound: true,
  );
  
  await localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(orderUpdatesChannel);
  
  await localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(incomingCallsChannel);
  
  // Show local notification if notification payload exists
  if (message.notification != null) {
    final notification = message.notification!;
    final title = notification.title ?? 'Order Update';
    final body = notification.body ?? '';
    
    // Determine channel ID based on notification type
    String channelId = 'order_updates';
    if (message.data['type'] == 'incoming_call') {
      channelId = 'incoming_calls';
    }
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'incoming_calls' ? 'Incoming Calls' : 'Order Updates',
      channelDescription: channelId == 'incoming_calls'
          ? 'Notifications for incoming calls'
          : 'Notifications for order status updates',
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
    
    final details = NotificationDetails(
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
    
    debugPrint('✅ Local notification shown in background handler');
  }
  
  // Store notification data for when app opens
  if (message.data['type'] == 'order_status_update' && message.data['orderId'] != null) {
    try {
      // Note: SharedPreferences requires WidgetsFlutterBinding.ensureInitialized()
      // which is already done in main.dart before Firebase initialization
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_order_navigation', message.data['orderId']!);
      debugPrint('✅ Stored order ID for navigation: ${message.data['orderId']}');
    } catch (e) {
      debugPrint('❌ Error storing notification data: $e');
    }
  }
}
