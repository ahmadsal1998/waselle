import 'dart:async';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/api_service.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/incoming_call_dialog.dart';
import 'socket_service.dart';
import '../main.dart'; // For GlobalNavigatorKey

class ZegoCallService {
  // Track active incoming call dialogs: Map<roomId, BuildContext>
  static final Map<String, BuildContext> _activeCallDialogs = {};

  /// Check and request microphone permission
  static Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    
    // Permission is permanently denied
    return false;
  }

  /// Show error dialog if permission is denied
  static void showPermissionError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'Please enable microphone permission in your device settings to make voice calls.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Generate room ID from order ID
  /// Ensures consistent room ID format: order_{orderId}_{driverId}_{customerId}
  /// Both caller and receiver must use the same room ID format
  static String generateRoomId(String orderId, {String? driverId, String? userId, String? customerId}) {
    // Determine driver and customer IDs
    String? finalDriverId = driverId;
    String? finalCustomerId = customerId ?? userId;
    
    // If we have both driverId and customerId, use them
    // Otherwise, fall back to order-only format (shouldn't happen in normal flow)
    if (finalDriverId != null && finalCustomerId != null) {
      // Sort IDs to ensure consistent room ID regardless of who calls
      final sortedIds = [finalDriverId, finalCustomerId]..sort();
      return "order_${orderId}_${sortedIds[0]}_${sortedIds[1]}";
    }
    
    // Fallback (shouldn't happen in production)
    debugPrint('⚠️ Warning: Room ID generated without both driver and customer IDs');
    return "order_$orderId";
  }

  /// Fetch Zego token from backend
  static Future<Map<String, dynamic>?> fetchToken({
    required String userId,
    required String userName,
    required String roomId,
  }) async {
    // Validate inputs
    if (userId.isEmpty) {
      debugPrint('Error: userId is empty');
      return null;
    }
    if (userName.isEmpty) {
      debugPrint('Error: userName is empty');
      return null;
    }
    if (roomId.isEmpty) {
      debugPrint('Error: roomId is empty');
      return null;
    }

    try {
      debugPrint('Fetching Zego token for userId: $userId, roomId: $roomId');
      final response = await ApiService.getZegoToken(
        userId: userId,
        userName: userName,
        roomId: roomId,
      );
      
      debugPrint('Zego token response received: ${response.runtimeType}');
      
      if (response is Map<String, dynamic>) {
        // Validate response structure
        if (response.containsKey('token') && response.containsKey('appID')) {
          debugPrint('Zego token fetched successfully');
          return response;
        } else {
          debugPrint('Error: Invalid token response structure. Missing token or appID');
          debugPrint('Response keys: ${response.keys.toList()}');
          return null;
        }
      } else {
        debugPrint('Error: Unexpected response type: ${response.runtimeType}');
        debugPrint('Response: $response');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching Zego token: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Provide more context about the error
      if (e.toString().contains('Connection') || e.toString().contains('network')) {
        debugPrint('Network error detected');
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('Authentication error detected');
      } else if (e.toString().contains('500') || e.toString().contains('server')) {
        debugPrint('Server error detected');
      }
      
      return null;
    }
  }

  /// Handle incoming call notification - show Accept/Reject dialog
  /// Can be called with or without explicit context (will use global navigator key if needed)
  static Future<void> handleIncomingCall({
    BuildContext? context,
    required String orderId,
    required String roomId,
    required String callerId,
    required String callerName,
  }) async {
    debugPrint('📞 Incoming call received: $callerName calling for order $orderId');
    
    // Try to get context from global navigator key if not provided
    BuildContext? effectiveContextNullable = context;
    if (effectiveContextNullable == null) {
      effectiveContextNullable = GlobalNavigatorKey.navigatorKey.currentContext;
    }
    
    if (effectiveContextNullable == null) {
      debugPrint('⚠️ No context available for incoming call, will retry when app resumes');
      return;
    }
    
    // Now we know it's not null, use a non-nullable variable
    final effectiveContext = effectiveContextNullable;
    
    // Get current user info
    final authViewModel = Provider.of<AuthViewModel>(effectiveContext, listen: false);
    final user = authViewModel.user;
    
    if (user == null) {
      debugPrint('Error: User not logged in, cannot handle call');
      return;
    }
    
    // Backend returns 'id' field, not '_id' - handle both for compatibility
    final userId = (user['id'] ?? user['_id'] ?? '').toString();
    
    if (userId.isEmpty) {
      debugPrint('Error: User ID is empty, cannot handle call');
      return;
    }
    
    // Show incoming call dialog with Accept/Reject options
    if (effectiveContext.mounted) {
      // Store dialog context for potential cancellation
      _activeCallDialogs[roomId] = effectiveContext;
      
      showDialog(
        context: effectiveContext,
        barrierDismissible: false,
        builder: (dialogContext) => IncomingCallDialog(
          callerName: callerName,
          orderId: orderId,
          roomId: roomId,
          callerId: callerId,
          onAccept: () async {
            // Remove from tracking
            _activeCallDialogs.remove(roomId);
            // Close dialog first
            Navigator.of(dialogContext).pop();
            // Wait for dialog to fully close before navigating
            await Future.delayed(const Duration(milliseconds: 300));
            // Then accept call using the original context for navigation
            if (effectiveContext.mounted) {
              _acceptCall(
                context: effectiveContext,
                orderId: orderId,
                roomId: roomId,
                callerId: callerId,
                callerName: callerName,
              );
            }
          },
          onReject: () {
            // Remove from tracking
            _activeCallDialogs.remove(roomId);
            _rejectCall(
              context: dialogContext,
              orderId: orderId,
              roomId: roomId,
              callerId: callerId,
            );
          },
        ),
      ).then((_) {
        // Remove from tracking when dialog is closed
        _activeCallDialogs.remove(roomId);
      });
    }
  }

  /// Accept incoming call and join the room
  static Future<void> _acceptCall({
    required BuildContext context,
    required String orderId,
    required String roomId,
    required String callerId,
    required String callerName,
  }) async {
    debugPrint('✅ Call accepted: Joining room $roomId');
    
    // Get current user info
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.user;
    
    if (user == null) {
      debugPrint('Error: User not logged in, cannot join call');
      return;
    }
    
    // Backend returns 'id' field, not '_id' - handle both for compatibility
    final userId = (user['id'] ?? user['_id'] ?? '').toString();
    final userName = user['name']?.toString() ?? 'User';
    
    if (userId.isEmpty) {
      debugPrint('Error: User ID is empty, cannot join call');
      return;
    }
    
    // Check microphone permission with enhanced error handling
    final hasPermission = await checkMicrophonePermission();
    if (!hasPermission) {
      debugPrint('❌ Microphone permission denied');
      if (context.mounted) {
        showPermissionError(context);
      }
      return;
    }
    
    // Double-check permission status before proceeding
    final permissionStatus = await Permission.microphone.status;
    if (!permissionStatus.isGranted) {
      debugPrint('❌ Microphone permission not granted, status: $permissionStatus');
      if (context.mounted) {
        showPermissionError(context);
      }
      return;
    }
    
    debugPrint('✅ Microphone permission granted');
    
    // Show loading indicator while fetching token
    BuildContext? loadingDialogContext;
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          loadingDialogContext = dialogContext;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
    }
    
    try {
      // Notify caller that call was accepted
      SocketService.emit('call-accepted', {
        'orderId': orderId,
        'roomId': roomId,
        'callerId': callerId,
        'receiverId': userId,
      });
      
      debugPrint('📤 Call acceptance notification sent to caller');
      
      // Fetch token for the receiver
      final tokenData = await fetchToken(
        userId: userId,
        userName: userName,
        roomId: roomId,
      );
      
      // Close loading dialog using the dialog context
      final dialogCtx = loadingDialogContext;
      if (dialogCtx != null && dialogCtx.mounted) {
        Navigator.of(dialogCtx).pop();
        loadingDialogContext = null;
      } else if (context.mounted) {
        // Fallback to original context
        Navigator.of(context).pop();
      }
      
      if (tokenData == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to join call. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final token = tokenData['token'] as String?;
      final appID = tokenData['appID'] as int?;
      
      if (token == null || appID == null) {
        debugPrint('Error: Invalid token data - token: ${token != null}, appID: ${appID != null}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid token received. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      debugPrint('✅ Token fetched successfully. Navigating to call screen...');
      debugPrint('Call parameters - appID: $appID, userId: $userId, userName: $userName, roomId: $roomId');
      debugPrint('Token length: ${token.length}, Token preview: ${token.substring(0, 20)}...');
      
      // Ensure context is still valid before navigation
      if (!context.mounted) {
        debugPrint('Error: Context no longer mounted, cannot navigate');
        return;
      }
      
      // Wait a brief moment to ensure loading dialog is fully dismissed
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Ensure context is still mounted after delay
      if (!context.mounted) {
        debugPrint('Error: Context no longer mounted after delay, cannot navigate');
        return;
      }
      
      // Navigate to call screen - receiver joins the same room
      // Use same pattern as caller for consistency (no Scaffold wrapper)
      debugPrint('🚀 Navigating to Zego call screen for receiver...');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (callContext) => ZegoUIKitPrebuiltCall(
            appID: appID,
            token: token,
            userID: userId,
            userName: userName,
            callID: roomId,
            config: ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
              ..turnOnMicrophoneWhenJoining = true
              ..turnOnCameraWhenJoining = false
              ..useSpeakerWhenJoining = true,
          ),
        ),
      ).then((_) {
        debugPrint('Call screen closed');
      }).catchError((error) {
        debugPrint('Error navigating to call screen: $error');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error joining call: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Exception in _acceptCall: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Close loading dialog if still open
      final dialogCtx = loadingDialogContext;
      if (dialogCtx != null && dialogCtx.mounted) {
        Navigator.of(dialogCtx).pop();
      } else if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining call: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Cancel incoming call (when caller disconnects)
  static void cancelIncomingCall({
    required String roomId,
    required String callerId,
  }) {
    debugPrint('🚫 Call cancelled: Caller $callerId disconnected');
    
    final dialogContext = _activeCallDialogs[roomId];
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
      _activeCallDialogs.remove(roomId);
      
      // Show notification that call was cancelled
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text('Call cancelled. Caller disconnected.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Reject incoming call
  static void _rejectCall({
    required BuildContext context,
    required String orderId,
    required String roomId,
    required String callerId,
  }) {
    debugPrint('❌ Call rejected: Notifying caller');
    
    // Get current user info
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.user;
    
    if (user == null) {
      debugPrint('Error: User not logged in, cannot reject call');
      return;
    }
    
    // Backend returns 'id' field, not '_id' - handle both for compatibility
    final userId = (user['id'] ?? user['_id'] ?? '').toString();
    
    // Notify caller that call was rejected
    SocketService.emit('call-rejected', {
      'orderId': orderId,
      'roomId': roomId,
      'callerId': callerId,
      'receiverId': userId,
    });
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Call rejected'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Start voice call
  static Future<void> startCall({
    required BuildContext context,
    required String orderId,
    required String userId,
    required String userName,
    String? driverId,
    String? customerId,
  }) async {
    // Validate inputs
    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid order ID. Cannot start call.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID is missing. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User name is missing. Cannot start call.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check microphone permission with enhanced error handling
    final hasPermission = await checkMicrophonePermission();
    if (!hasPermission) {
      debugPrint('❌ Microphone permission denied');
      showPermissionError(context);
      return;
    }
    
    // Double-check permission status before proceeding
    final permissionStatus = await Permission.microphone.status;
    if (!permissionStatus.isGranted) {
      debugPrint('❌ Microphone permission not granted, status: $permissionStatus');
      showPermissionError(context);
      return;
    }
    
    debugPrint('✅ Microphone permission granted');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Prevent self-calling
      final targetReceiverId = driverId ?? customerId;
      if (targetReceiverId != null && targetReceiverId == userId) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot call yourself.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      // Generate room ID - ensure both driver and customer IDs are included
      // When driver calls: driverId is null (caller is driver), customerId is set (receiver)
      // When customer calls: customerId is null (caller is customer), driverId is set (receiver)
      String? finalDriverId;
      String? finalCustomerId;
      
      if (driverId == null && customerId != null) {
        // Driver is calling customer
        finalDriverId = userId; // Current user (caller) is the driver
        finalCustomerId = customerId; // Receiver is the customer
      } else if (customerId == null && driverId != null) {
        // Customer is calling driver
        finalDriverId = driverId; // Receiver is the driver
        finalCustomerId = userId; // Current user (caller) is the customer
      } else {
        // Fallback - shouldn't happen in normal flow
        debugPrint('⚠️ Warning: Unexpected call parameters - driverId: $driverId, customerId: $customerId');
        finalDriverId = driverId;
        finalCustomerId = customerId ?? userId;
      }
      
      final roomId = generateRoomId(
        orderId,
        driverId: finalDriverId,
        customerId: finalCustomerId,
      );
      debugPrint('Starting call with roomId: $roomId, userId: $userId, userName: $userName');
      debugPrint('Room ID components - orderId: $orderId, driverId: $finalDriverId, customerId: $finalCustomerId');

      // Fetch token from backend
      final tokenData = await fetchToken(
        userId: userId,
        userName: userName,
        roomId: roomId,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (tokenData == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start call. Please check your connection and try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final token = tokenData['token'] as String?;
      final appID = tokenData['appID'] as int?;

      if (token == null || appID == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid token received. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      debugPrint('✅ Caller token fetched successfully');
      debugPrint('Caller parameters - appID: $appID, userId: $userId, userName: $userName, roomId: $roomId');
      debugPrint('Token length: ${token.length}, Token preview: ${token.substring(0, 20)}...');

      // Track call acceptance status
      bool callAccepted = false;
      bool callRejected = false;
      bool callConnected = false; // Track if call actually connected
      String? receiverId;
      Timer? timeoutTimer; // Store timer reference to cancel it
      
      // Helper function to clean up listeners and cancel timeout
      void cleanupCallListeners() {
        SocketService.off('call-accepted');
        SocketService.off('call-rejected');
        timeoutTimer?.cancel();
      }
      
      // Notify receiver via Socket.IO before starting call
      if (driverId != null || customerId != null) {
        receiverId = driverId ?? customerId;
        if (receiverId != null && receiverId.isNotEmpty) {
          debugPrint('Sending call notification to receiver: $receiverId');
          
          // Set up listener for call rejection/timeout
          void onCallAccepted(dynamic data) {
            if (data['roomId'] == roomId && data['callerId'] == userId) {
              callAccepted = true;
              timeoutTimer?.cancel(); // Cancel timeout when call is accepted
              cleanupCallListeners();
              debugPrint('✅ Call accepted by receiver - timeout cancelled');
            }
          }
          
          void onCallRejected(dynamic data) {
            if (data['roomId'] == roomId && data['callerId'] == userId) {
              callRejected = true;
              timeoutTimer?.cancel(); // Cancel timeout when call is rejected
              cleanupCallListeners();
              debugPrint('❌ Call rejected by receiver');
              
              if (context.mounted) {
                Navigator.of(context).pop(); // Close call screen if open
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Call rejected by receiver'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          }
          
          SocketService.on('call-accepted', onCallAccepted);
          SocketService.on('call-rejected', onCallRejected);
          
          // Set timeout for call acceptance (60 seconds - increased for Render free hosting delays)
          // This timeout will be cancelled if call-accepted is received OR if call connects
          timeoutTimer = Timer(const Duration(seconds: 60), () {
            if (!callAccepted && !callRejected && !callConnected && context.mounted) {
              cleanupCallListeners();
              debugPrint('⏱️ Call timeout: No response from receiver after 60 seconds');
              
              // Close call screen if it's open
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Call timed out. Receiver did not answer.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          });
          
          SocketService.emit('call-initiate', {
            'orderId': orderId,
            'roomId': roomId,
            'callerId': userId,
            'callerName': userName,
            'receiverId': receiverId,
          });
        }
      }

      // Navigate to call screen using token
      // Note: Call will only connect if receiver accepts
      if (context.mounted) {
        debugPrint('🚀 Navigating to Zego call screen for caller...');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (callContext) => ZegoUIKitPrebuiltCall(
              appID: appID,
              token: token,
              userID: userId,
              userName: userName,
              callID: roomId,
              config: ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
                ..turnOnMicrophoneWhenJoining = true
                ..turnOnCameraWhenJoining = false
                ..useSpeakerWhenJoining = true,
            ),
          ),
        ).then((_) {
          // Clean up listeners when call screen is closed
          cleanupCallListeners();
          
          // If call screen is closed before receiver accepts, cancel the call
          if (!callAccepted && !callRejected && !callConnected && receiverId != null && receiverId.isNotEmpty) {
            debugPrint('⚠️ Call screen closed before receiver accepted, cancelling call...');
            SocketService.emit('call-cancelled', {
              'orderId': orderId,
              'roomId': roomId,
              'callerId': userId,
              'receiverId': receiverId,
            });
          }
        });
        
        // Monitor call connection status - if call connects, cancel timeout
        // We'll check this periodically or use a delayed check after navigation
        Future.delayed(const Duration(seconds: 5), () {
          // After 5 seconds, if we're still in the call screen, assume call connected
          // This handles cases where call-accepted event is delayed but call actually connected
          if (context.mounted && !callAccepted && !callRejected) {
            // Check if we're still on the call screen (call connected)
            // Note: This is a fallback - ideally call-accepted event should arrive
            debugPrint('⏳ Checking if call connected (fallback check)...');
            // The timeout will be cancelled if call-accepted arrives, or if call screen closes
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Exception starting call: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        String errorMessage = 'Error starting call: ${e.toString()}';
        
        // Provide more user-friendly error messages
        if (e.toString().contains('Connection') || e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection and try again.';
        } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          errorMessage = 'Authentication failed. Please log in again.';
        } else if (e.toString().contains('500') || e.toString().contains('server')) {
          errorMessage = 'Server error. Please try again later.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

