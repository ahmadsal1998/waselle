import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/api_service.dart';
import '../main.dart'; // For GlobalNavigatorKey
import '../l10n/app_localizations.dart';

// Note: Background handler is now registered in main.dart BEFORE Firebase.initializeApp()
// This ensures it works when the app is terminated

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Show feedback to user about permission result
      _showNotificationPermissionResult(settings.authorizationStatus);

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (kDebugMode) {
          print('✅ User granted notification permission');
        }
      } else {
        if (kDebugMode) {
          print('❌ User declined notification permission');
        }
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

      // Create notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'order_updates',
        'Order Updates',
        description: 'Notifications for order status updates',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        if (kDebugMode) {
          print('✅ FCM Token: $_fcmToken');
        }
        await _registerToken(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          print('🔄 FCM Token refreshed: $newToken');
        }
        _fcmToken = newToken;
        _registerToken(newToken);
      });

      // Set up message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification when app is opened from terminated state
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print('📱 App opened from notification (terminated state)');
        }
        // Wait a bit for app to initialize before handling
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationTap(initialMessage);
        });
      }

      // Note: Background handler is registered in main.dart BEFORE Firebase.initializeApp()
      // This is required for notifications to work when app is terminated

      _isInitialized = true;
      if (kDebugMode) {
        print('✅ Notification service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing notification service: $e');
      }
    }
  }

  /// Register FCM token with backend
  Future<void> _registerToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('fcm_token');
      
      // Only register if token changed
      if (storedToken != token) {
        await ApiService.registerFCMToken(token);
        await prefs.setString('fcm_token', token);
        if (kDebugMode) {
          print('✅ FCM token registered with backend');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error registering FCM token: $e');
      }
    }
  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('📨 Foreground message received: ${message.messageId}');
      print('   Notification: ${message.notification?.title} - ${message.notification?.body}');
      print('   Data: ${message.data}');
    }
    
    final notification = message.notification;
    final data = message.data;

    // CRITICAL FIX: On iOS, if the message has a notification field,
    // iOS will automatically show the notification via APNS.
    // We should NOT show a local notification in this case to avoid duplicates.
    // Only show local notifications for data-only messages or on Android.
    if (Platform.isIOS && notification != null) {
      // iOS will show the notification automatically via APNS
      // Just process the data, don't show local notification
      if (kDebugMode) {
        print('📱 iOS: Notification field present, iOS will show automatically. Skipping local notification to avoid duplicate.');
      }
      return;
    }

    // Show local notification when app is in foreground (Android or data-only messages)
    // Use notification payload if available, otherwise use data
    String title = 'Order Update';
    String body = '';
    
    if (notification != null) {
      title = notification.title ?? title;
      body = notification.body ?? body;
    } else if (data['title'] != null) {
      title = data['title']!;
      body = data['body'] ?? '';
    }
    
    // Only show if we have a body or title
    if (body.isNotEmpty || title != 'Order Update') {
      await _showLocalNotification(
        title: title,
        body: body,
        data: data,
      );
      if (kDebugMode) {
        print('✅ Local notification shown in foreground');
      }
    } else {
      if (kDebugMode) {
        print('⚠️ No notification content to display');
      }
    }
  }

  /// Handle notification tap (when app is in background or terminated)
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('👆 Notification tapped: ${message.messageId}');
    }
    final data = message.data;
    
    if (data['type'] == 'order_status_update' && data['orderId'] != null) {
      // Navigate to order details
      // This will be handled by the app's navigation system
      // Store the order ID for navigation
      _storePendingNavigation(data['orderId']);
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('👆 Local notification tapped: ${response.id}');
    }
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
        if (kDebugMode) {
          print('❌ Error parsing notification payload: $e');
        }
      }
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
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

  /// Store pending navigation order ID
  void _storePendingNavigation(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_order_navigation', orderId);
  }

  /// Get and clear pending navigation order ID
  static Future<String?> getPendingNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final orderId = prefs.getString('pending_order_navigation');
    if (orderId != null) {
      await prefs.remove('pending_order_navigation');
    }
    return orderId;
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Show notification permission result dialog to user
  void _showNotificationPermissionResult(AuthorizationStatus status) {
    final context = GlobalNavigatorKey.navigatorKey.currentContext;
    if (context == null) {
      if (kDebugMode) {
        print('⚠️ No context available to show permission result dialog');
      }
      return;
    }

    // Get localization
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      if (kDebugMode) {
        print('⚠️ Localization not available');
      }
      return;
    }

    // Show dialog after a short delay to ensure system dialog is dismissed
    Future.delayed(const Duration(milliseconds: 500), () {
      if (GlobalNavigatorKey.navigatorKey.currentContext == null) return;
      
      final currentContext = GlobalNavigatorKey.navigatorKey.currentContext!;
      final currentL10n = AppLocalizations.of(currentContext);
      if (currentL10n == null) return;

      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        // Permission granted - show success message
        showDialog(
          context: currentContext,
          barrierDismissible: true,
          builder: (context) => AlertDialog(
            title: Text(currentL10n.notificationPermissionGranted),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  status == AuthorizationStatus.provisional
                      ? currentL10n.notificationPermissionProvisionalMessage
                      : currentL10n.notificationPermissionGrantedMessage,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(currentL10n.ok),
              ),
            ],
          ),
        );
      } else {
        // Permission denied - show informative message
        showDialog(
          context: currentContext,
          barrierDismissible: true,
          builder: (context) => AlertDialog(
            title: Text(currentL10n.notificationPermissionDenied),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  currentL10n.notificationPermissionDeniedMessage,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(currentL10n.ok),
              ),
            ],
          ),
        );
      }
    });
  }
}

