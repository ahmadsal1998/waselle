import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../repositories/api_service.dart';
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
      // Request notification permissions (platform-specific)
      bool permissionGranted = await _requestNotificationPermissions();
      
      if (!permissionGranted) {
        debugPrint('⚠️ Notification permission not granted');
        // Still continue initialization - token might still be generated
        // but notifications won't be displayed
      } else {
        debugPrint('✅ Notification permission granted');
      }

      // Get FCM token (platform-specific handling)
      // CRITICAL: Keep Android and iOS paths completely separate to avoid APNS errors on Android
      if (Platform.isAndroid) {
        // Android: Get token directly without any APNS-related code
        // IMPORTANT: Token can be retrieved even if notification permissions are denied
        await _retrieveAndroidToken();
      } else if (Platform.isIOS) {
        // iOS: Handle APNS token first, then get FCM token
        try {
          // On iOS, ensure APNS token is available first
          try {
            final apnsToken = await _firebaseMessaging.getAPNSToken();
            if (apnsToken == null) {
              debugPrint('⚠️ APNS token not available yet on iOS, will retry later');
              // Still try to get FCM token
            } else {
              debugPrint('✅ APNS token available on iOS');
            }
          } catch (e) {
            debugPrint('⚠️ Error getting APNS token on iOS: $e');
            // Continue anyway - might work without it
          }
          
          _fcmToken = await _firebaseMessaging.getToken();
          if (_fcmToken != null) {
            debugPrint('📱 FCM Token retrieved (iOS): ${_fcmToken!.substring(0, 20)}...');
            debugPrint('📱 Full FCM Token: $_fcmToken');
            await _saveTokenToBackend(_fcmToken!);
          } else {
            debugPrint('⚠️ FCM Token is null on iOS - Firebase may not be properly configured');
          }
        } catch (e) {
          debugPrint('❌ Error getting FCM token on iOS: $e');
          // Don't rethrow - allow initialization to continue
        }
      } else {
        // Other platforms (Web, Desktop, etc.)
        try {
          _fcmToken = await _firebaseMessaging.getToken();
          if (_fcmToken != null) {
            debugPrint('📱 FCM Token retrieved (other platform): ${_fcmToken!.substring(0, 20)}...');
            await _saveTokenToBackend(_fcmToken!);
          }
        } catch (e) {
          debugPrint('⚠️ Error getting FCM token on other platform: $e');
          // Don't block initialization
        }
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM token refreshed: ${newToken.substring(0, 20)}...');
        debugPrint('🔄 Full refreshed token: $newToken');
        _fcmToken = newToken;
        _saveTokenToBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message when app is opened from terminated state
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification (terminated state)
      try {
        RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('📱 App opened from notification (terminated state)');
          // Wait a bit for app to initialize
          Future.delayed(const Duration(seconds: 1), () {
            _handleNotificationTap(initialMessage);
          });
        }
      } catch (e) {
        debugPrint('⚠️ Error checking initial message: $e');
        // Continue initialization
      }

      _isInitialized = true;
      debugPrint('✅ FCM Service initialized');
    } catch (e) {
      // Log error but don't prevent initialization from completing
      // This ensures the app can still function even if FCM setup fails
      debugPrint('❌ Error initializing FCM service: $e');
      // Still mark as initialized to prevent retry loops
      _isInitialized = true;
    }
  }

  /// Request notification permissions (platform-specific)
  Future<bool> _requestNotificationPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Android 13+ requires explicit POST_NOTIFICATIONS permission
        try {
          if (await Permission.notification.isDenied) {
            final status = await Permission.notification.request();
            if (status.isGranted) {
              debugPrint('✅ Android notification permission granted');
              return true;
            } else if (status.isPermanentlyDenied) {
              debugPrint('❌ Android notification permission permanently denied');
              return false;
            } else {
              debugPrint('⚠️ Android notification permission denied');
              return false;
            }
          } else if (await Permission.notification.isGranted) {
            debugPrint('✅ Android notification permission already granted');
            return true;
          } else {
            debugPrint('⚠️ Android notification permission status unknown');
            // For Android < 13, permission is granted by default
            return true;
          }
        } catch (e) {
          debugPrint('⚠️ Error checking Android notification permission: $e');
          // For Android < 13, permission is granted by default
          return true;
        }
      } else if (Platform.isIOS) {
        // iOS uses Firebase Messaging's requestPermission
        // CRITICAL: This method should NEVER be called on Android as it may trigger APNS code
        try {
          NotificationSettings settings = await _firebaseMessaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            debugPrint('✅ iOS notification permission granted');
            return true;
          } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
            debugPrint('⚠️ iOS provisional notification permission granted');
            return true;
          } else {
            debugPrint('❌ iOS notification permission denied');
            return false;
          }
        } catch (e) {
          debugPrint('⚠️ Error requesting iOS notification permission: $e');
          // Continue anyway - token might still be generated
          return true;
        }
      }
      // Default: allow initialization to continue
      return true;
    } catch (e) {
      debugPrint('⚠️ Error in _requestNotificationPermissions: $e');
      // Don't block initialization - token might still work
      return true;
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

  /// Retrieve Android FCM token with retry logic
  Future<void> _retrieveAndroidToken({int retryCount = 0, int maxRetries = 3}) async {
    try {
      debugPrint('📱 Attempting to retrieve FCM token on Android (attempt ${retryCount + 1}/$maxRetries)...');
      
      // Ensure Firebase is initialized
      if (!Firebase.apps.isNotEmpty) {
        debugPrint('⚠️ Firebase not initialized, initializing now...');
        await Firebase.initializeApp();
      }
      
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        debugPrint('✅ FCM Token retrieved successfully (Android): ${_fcmToken!.substring(0, 20)}...');
        debugPrint('📱 Full FCM Token: $_fcmToken');
        // Try to save token, but don't fail if user is not authenticated yet
        await _saveTokenToBackend(_fcmToken!);
      } else {
        debugPrint('⚠️ FCM Token is null or empty on Android');
        if (retryCount < maxRetries) {
          debugPrint('🔄 Retrying token retrieval in 3 seconds...');
          await Future.delayed(const Duration(seconds: 3));
          await _retrieveAndroidToken(retryCount: retryCount + 1, maxRetries: maxRetries);
        } else {
          debugPrint('❌ Failed to retrieve FCM token after $maxRetries attempts');
          debugPrint('⚠️ Possible causes:');
          debugPrint('   1. google-services.json is missing or incorrect');
          debugPrint('   2. Firebase project configuration issue');
          debugPrint('   3. Network connectivity issue');
          debugPrint('   4. Device/emulator Firebase setup issue');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting FCM token on Android: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      
      if (retryCount < maxRetries) {
        final delaySeconds = (retryCount + 1) * 2; // Exponential backoff: 2s, 4s, 6s
        debugPrint('🔄 Retrying token retrieval in $delaySeconds seconds...');
        await Future.delayed(Duration(seconds: delaySeconds));
        await _retrieveAndroidToken(retryCount: retryCount + 1, maxRetries: maxRetries);
      } else {
        debugPrint('❌ Failed to retrieve FCM token after $maxRetries attempts');
        debugPrint('⚠️ Error details: $e');
      }
    }
  }

  /// Manually retry FCM token retrieval (useful for debugging or after fixing Firebase config)
  Future<String?> retryTokenRetrieval() async {
    if (Platform.isAndroid) {
      await _retrieveAndroidToken();
      return _fcmToken;
    } else if (Platform.isIOS) {
      try {
        _fcmToken = await _firebaseMessaging.getToken();
        if (_fcmToken != null) {
          await _saveTokenToBackend(_fcmToken!);
        }
        return _fcmToken;
      } catch (e) {
        debugPrint('❌ Error retrying FCM token on iOS: $e');
        return null;
      }
    }
    return null;
  }

  /// Save FCM token to backend
  Future<void> _saveTokenToBackend(String token) async {
    try {
      // Validate token
      if (token.isEmpty) {
        debugPrint('⚠️ Cannot save empty FCM token');
        return;
      }
      
      // Check if user is authenticated before saving token
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      
      if (authToken == null) {
        debugPrint('⚠️ User not authenticated, storing FCM token for later: ${token.substring(0, 20)}...');
        // Store token temporarily to save after login
        await prefs.setString('pending_fcm_token', token);
        return;
      }
      
      debugPrint('📤 Sending FCM token to backend: ${token.substring(0, 20)}...');
      await ApiService.updateFCMToken(token);
      debugPrint('✅ FCM token saved to backend successfully');
      
      // Clear pending token if save was successful
      await prefs.remove('pending_fcm_token');
    } catch (e) {
      debugPrint('❌ Error saving FCM token to backend: $e');
      debugPrint('   Token: ${token.substring(0, 20)}...');
      
      // Store token to retry later
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_fcm_token', token);
        debugPrint('💾 FCM token stored for retry after authentication');
      } catch (storageError) {
        debugPrint('❌ Failed to store pending FCM token: $storageError');
      }
    }
  }

  /// Save pending FCM token after authentication
  Future<void> savePendingToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingToken = prefs.getString('pending_fcm_token');
      
      if (pendingToken != null) {
        debugPrint('📱 Saving pending FCM token after authentication');
        await _saveTokenToBackend(pendingToken);
      } else if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        // If no pending token but we have a token, try to save it
        debugPrint('📱 Saving current FCM token after authentication');
        await _saveTokenToBackend(_fcmToken!);
      } else {
        // No token available, try to retrieve it
        debugPrint('⚠️ No FCM token available, attempting to retrieve...');
        if (Platform.isAndroid) {
          await _retrieveAndroidToken();
          if (_fcmToken != null && _fcmToken!.isNotEmpty) {
            await _saveTokenToBackend(_fcmToken!);
          }
        } else if (Platform.isIOS) {
          try {
            _fcmToken = await _firebaseMessaging.getToken();
            if (_fcmToken != null) {
              await _saveTokenToBackend(_fcmToken!);
            }
          } catch (e) {
            debugPrint('❌ Error retrieving FCM token on iOS: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving pending FCM token: $e');
    }
  }

  /// Get current FCM token
  String? get token => _fcmToken;

  /// Check if FCM is initialized
  bool get isInitialized => _isInitialized;
  
  /// Check if FCM token is available
  bool get hasToken => _fcmToken != null && _fcmToken!.isNotEmpty;
  
  /// Diagnostic method to check FCM setup status
  Future<Map<String, dynamic>> getDiagnostics() async {
    final diagnostics = <String, dynamic>{
      'isInitialized': _isInitialized,
      'hasToken': hasToken,
      'tokenLength': _fcmToken?.length ?? 0,
      'platform': Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Other'),
      'firebaseInitialized': Firebase.apps.isNotEmpty,
    };
    
    if (Platform.isAndroid) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final pendingToken = prefs.getString('pending_fcm_token');
        diagnostics['pendingTokenStored'] = pendingToken != null;
        diagnostics['userAuthenticated'] = prefs.getString('token') != null;
      } catch (e) {
        diagnostics['prefsError'] = e.toString();
      }
    }
    
    return diagnostics;
  }
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

