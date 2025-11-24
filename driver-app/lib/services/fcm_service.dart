import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart';
import 'zego_call_service.dart';
import '../main.dart'; // For GlobalNavigatorKey

/// Firebase Cloud Messaging service for handling push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
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
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Foreground message received: ${message.messageId}');
    debugPrint('   Data: ${message.data}');
    debugPrint('   Notification: ${message.notification?.title}');

    // Handle incoming call notification
    if (message.data['type'] == 'incoming_call') {
      _handleIncomingCallNotification(message.data);
    }
  }

  /// Handle notification tap (when user taps notification)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.messageId}');
    debugPrint('   Data: ${message.data}');

    // Handle incoming call notification
    if (message.data['type'] == 'incoming_call') {
      _handleIncomingCallNotification(message.data);
    }
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

    // Handle the call
    ZegoCallService.handleIncomingCall(
      orderId: orderId,
      roomId: roomId,
      callerId: callerId,
      callerName: callerName,
    );
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
  debugPrint('📨 Background message received: ${message.messageId}');
  debugPrint('   Data: ${message.data}');
  
  // Background messages are handled here
  // The app will handle the notification tap via onMessageOpenedApp
}

