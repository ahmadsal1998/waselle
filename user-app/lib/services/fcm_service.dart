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
  /// This is called on every app start to ensure FCM is always ready
  Future<void> initialize() async {
    if (_isInitialized) {
      // Even if already initialized, verify token is synced
      // This handles cases where app was reinstalled or token became invalid
      debugPrint('🔄 FCM already initialized, verifying token sync...');
      await _verifyAndSyncToken();
      return;
    }

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
        await _retrieveIOSToken();
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
      // CRITICAL: This listener ensures tokens are always refreshed when Firebase generates a new one
      // This happens automatically when app is reinstalled, token expires, or Firebase refreshes it
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM token refreshed automatically by Firebase: ${newToken.substring(0, 20)}...');
        debugPrint('🔄 Full refreshed token: $newToken');
        _fcmToken = newToken;
        // Always try to save to backend immediately when token refreshes
        // This ensures backend always has the latest token
        _saveTokenToBackend(newToken).then((success) {
          if (success) {
            debugPrint('✅ Refreshed FCM token synced to backend successfully');
          } else {
            debugPrint('⚠️ Refreshed FCM token stored locally, will sync when authenticated');
          }
        });
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
      
      // CRITICAL: After initialization, verify token is synced
      // This ensures token is sent to backend even if user is already authenticated
      // This handles cases where backend removed invalid token
      await _verifyAndSyncToken();
    } catch (e) {
      // Log error but don't prevent initialization from completing
      // This ensures the app can still function even if FCM setup fails
      debugPrint('❌ Error initializing FCM service: $e');
      // Still mark as initialized to prevent retry loops
      _isInitialized = true;
    }
  }

  /// Verify token is synced to backend and sync if needed
  /// This is called on app start and periodically to ensure token is always up to date
  Future<void> _verifyAndSyncToken() async {
    try {
      // Check if user is authenticated
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      
      if (authToken == null) {
        debugPrint('🔍 Token sync check: User not authenticated, will sync after login');
        return;
      }
      
      // If we have a token, ensure it's synced
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        debugPrint('🔍 Token sync check: Verifying token is synced to backend...');
        // Try to sync token (will only send if not already synced)
        await _saveTokenToBackend(_fcmToken!);
      } else {
        // No token yet, try to retrieve one
        debugPrint('🔍 Token sync check: No token found, retrieving...');
        if (Platform.isAndroid) {
          await _retrieveAndroidToken(retryCount: 0, maxRetries: 2);
        } else if (Platform.isIOS) {
          await _retrieveIOSToken(retryCount: 0, maxRetries: 2);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error verifying token sync: $e');
      // Don't throw - this is a background check
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

  /// Retrieve iOS FCM token with APNS token handling and retry logic
  Future<void> _retrieveIOSToken({int retryCount = 0, int maxRetries = 5}) async {
    try {
      debugPrint('📱 Attempting to retrieve FCM token on iOS (attempt ${retryCount + 1}/$maxRetries)...');
      
      // CRITICAL: On iOS, we MUST get APNS token first before getting FCM token
      // Wait for APNS token with retry logic
      String? apnsToken;
      int apnsRetryCount = 0;
      const maxApnsRetries = 10;
      
      while (apnsToken == null && apnsRetryCount < maxApnsRetries) {
        try {
          apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            debugPrint('✅ APNS token retrieved on iOS: ${apnsToken.substring(0, 20)}...');
            break;
          } else {
            apnsRetryCount++;
            if (apnsRetryCount < maxApnsRetries) {
              debugPrint('⏳ APNS token not available yet, waiting 1 second... (attempt $apnsRetryCount/$maxApnsRetries)');
              await Future.delayed(const Duration(seconds: 1));
            }
          }
        } catch (e) {
          apnsRetryCount++;
          if (apnsRetryCount < maxApnsRetries) {
            debugPrint('⚠️ Error getting APNS token, retrying... (attempt $apnsRetryCount/$maxApnsRetries): $e');
            await Future.delayed(const Duration(seconds: 1));
          } else {
            debugPrint('❌ Failed to get APNS token after $maxApnsRetries attempts: $e');
            // Still try to get FCM token - sometimes it works without APNS token
          }
        }
      }
      
      if (apnsToken == null && apnsRetryCount >= maxApnsRetries) {
        debugPrint('⚠️ APNS token not available after $maxApnsRetries attempts, trying FCM token anyway...');
      }
      
      // Now try to get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        debugPrint('✅ FCM Token retrieved successfully (iOS): ${_fcmToken!.substring(0, 20)}...');
        debugPrint('📱 Full FCM Token: $_fcmToken');
        await _saveTokenToBackend(_fcmToken!);
      } else {
        debugPrint('⚠️ FCM Token is null or empty on iOS');
        if (retryCount < maxRetries) {
          final delaySeconds = (retryCount + 1) * 2; // Exponential backoff: 2s, 4s, 6s, 8s, 10s
          debugPrint('🔄 Retrying FCM token retrieval in $delaySeconds seconds...');
          await Future.delayed(Duration(seconds: delaySeconds));
          await _retrieveIOSToken(retryCount: retryCount + 1, maxRetries: maxRetries);
        } else {
          debugPrint('❌ Failed to retrieve FCM token after $maxRetries attempts');
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token on iOS: $e');
      
      // Check if it's the APNS token error
      if (e.toString().contains('apns-token-not-set')) {
        if (retryCount < maxRetries) {
          final delaySeconds = (retryCount + 1) * 2;
          debugPrint('🔄 APNS token not set, retrying in $delaySeconds seconds...');
          await Future.delayed(Duration(seconds: delaySeconds));
          await _retrieveIOSToken(retryCount: retryCount + 1, maxRetries: maxRetries);
        } else {
          debugPrint('❌ Failed to retrieve FCM token after $maxRetries attempts (APNS token issue)');
        }
      } else {
        // Other errors - don't retry indefinitely
        debugPrint('❌ Non-APNS error getting FCM token: $e');
      }
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
      await _retrieveIOSToken(retryCount: 0, maxRetries: 3);
      return _fcmToken;
    }
    return null;
  }

  /// Save FCM token to backend
  /// Returns true if successful, false otherwise
  /// CRITICAL: This method always updates the token on backend, never skips
  Future<bool> _saveTokenToBackend(String token) async {
    try {
      // Validate token
      if (token.isEmpty) {
        debugPrint('⚠️ Cannot save empty FCM token');
        return false;
      }
      
      // Validate token format (FCM tokens are typically long strings)
      if (token.length < 50) {
        debugPrint('⚠️ FCM token seems invalid (too short): ${token.length} characters');
        return false;
      }
      
      // Check if user is authenticated before saving token
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      
      if (authToken == null) {
        debugPrint('⚠️ User not authenticated, storing FCM token for later: ${token.substring(0, 20)}...');
        // Store token temporarily to save after login
        await prefs.setString('pending_fcm_token', token);
        return false;
      }
      
      // CRITICAL: Always send token to backend, even if we think it's already there
      // This ensures backend always has the latest token, especially after app reinstallation
      // or when backend removed an invalid token
      debugPrint('📤 Sending FCM token to backend: ${token.substring(0, 20)}...');
      debugPrint('📤 Full token length: ${token.length} characters');
      debugPrint('📤 This will UPDATE the token on backend (not create new)');
      
      await ApiService.updateFCMToken(token);
      debugPrint('✅ FCM token saved/updated to backend successfully');
      
      // Clear pending token if save was successful
      await prefs.remove('pending_fcm_token');
      await prefs.remove('needs_fcm_token_refresh');
      
      // Store last successful sync time to avoid unnecessary syncs
      await prefs.setInt('last_fcm_token_sync', DateTime.now().millisecondsSinceEpoch);
      
      return true;
    } catch (e) {
      debugPrint('❌ Error saving FCM token to backend: $e');
      debugPrint('   Token: ${token.substring(0, 20)}...');
      debugPrint('   Token length: ${token.length}');
      
      // Store token to retry later
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_fcm_token', token);
        debugPrint('💾 FCM token stored for retry after authentication');
      } catch (storageError) {
        debugPrint('❌ Failed to store pending FCM token: $storageError');
      }
      return false;
    }
  }

  /// Save pending FCM token after authentication
  /// This method ensures a fresh token is retrieved and synced to backend
  /// CRITICAL: Called after login to ensure token is always synced
  Future<void> savePendingToken() async {
    try {
      debugPrint('📱 Starting FCM token sync after authentication...');
      
      // First, try to save any pending token
      final prefs = await SharedPreferences.getInstance();
      final pendingToken = prefs.getString('pending_fcm_token');
      
      if (pendingToken != null && pendingToken.isNotEmpty) {
        debugPrint('📱 Found pending FCM token, saving to backend...');
        final success = await _saveTokenToBackend(pendingToken);
        if (success) {
          // Clear pending token after successful save
          await prefs.remove('pending_fcm_token');
          _fcmToken = pendingToken;
          debugPrint('✅ Pending FCM token saved successfully');
          return;
        }
      }
      
      // Force refresh token to ensure we have the latest one
      // This is critical after app reinstallation or when backend removed invalid token
      debugPrint('🔄 Forcing FCM token refresh after authentication...');
      String? newToken;
      
      if (Platform.isAndroid) {
        // Force retrieve Android token with retry
        await _retrieveAndroidToken(retryCount: 0, maxRetries: 5);
        newToken = _fcmToken;
      } else if (Platform.isIOS) {
        // Force retrieve iOS token with retry and APNS handling
        await _retrieveIOSToken(retryCount: 0, maxRetries: 5);
        newToken = _fcmToken;
      }
      
      if (newToken != null && newToken.isNotEmpty) {
        _fcmToken = newToken;
        debugPrint('✅ FCM token retrieved: ${newToken.substring(0, 20)}...');
        final success = await _saveTokenToBackend(newToken);
        if (success) {
          debugPrint('✅ FCM token synced to backend successfully');
          // Clear any pending token
          await prefs.remove('pending_fcm_token');
          await prefs.remove('needs_fcm_token_refresh');
        } else {
          // Store as pending if save failed (shouldn't happen if authenticated)
          await prefs.setString('pending_fcm_token', newToken);
          debugPrint('⚠️ FCM token save failed, stored locally for retry');
        }
      } else {
        debugPrint('⚠️ Could not retrieve FCM token, will retry later');
        // Schedule retry after a delay
        Future.delayed(const Duration(seconds: 5), () {
          savePendingToken();
        });
      }
    } catch (e) {
      debugPrint('❌ Error saving pending FCM token: $e');
      // Retry after delay
      Future.delayed(const Duration(seconds: 5), () {
        savePendingToken();
      });
    }
  }
  
  /// Periodic token sync check
  /// This ensures token is synced even if initial sync failed
  /// Called periodically to catch cases where backend removed token
  Future<void> periodicTokenSyncCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      
      // Only check if user is authenticated
      if (authToken == null) {
        return;
      }
      
      // Check last sync time to avoid unnecessary syncs
      final lastSync = prefs.getInt('last_fcm_token_sync') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastSync = now - lastSync;
      
      // Only sync if it's been more than 1 hour since last sync
      // This prevents excessive API calls while ensuring token stays fresh
      if (timeSinceLastSync < 3600000) { // 1 hour in milliseconds
        return;
      }
      
      debugPrint('🔄 Periodic token sync check: Verifying token is synced...');
      
      // If we have a token, ensure it's synced
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await _saveTokenToBackend(_fcmToken!);
      } else {
        // No token, try to retrieve one
        if (Platform.isAndroid) {
          await _retrieveAndroidToken(retryCount: 0, maxRetries: 2);
        } else if (Platform.isIOS) {
          await _retrieveIOSToken(retryCount: 0, maxRetries: 2);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error in periodic token sync check: $e');
    }
  }
  
  /// Force refresh FCM token and sync to backend
  /// This is useful after app reinstallation or when token might be stale
  Future<bool> forceRefreshAndSyncToken() async {
    try {
      debugPrint('🔄 Force refreshing FCM token...');
      
      String? newToken;
      if (Platform.isAndroid) {
        await _retrieveAndroidToken(retryCount: 0, maxRetries: 5);
        newToken = _fcmToken;
      } else if (Platform.isIOS) {
        await _retrieveIOSToken(retryCount: 0, maxRetries: 3);
        newToken = _fcmToken;
      }
      
      if (newToken != null && newToken.isNotEmpty) {
        final success = await _saveTokenToBackend(newToken);
        if (success) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('needs_fcm_token_refresh');
          debugPrint('✅ FCM token force refreshed and synced successfully');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error force refreshing FCM token: $e');
      return false;
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

