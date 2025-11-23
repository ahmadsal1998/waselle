import 'dart:async';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/api_service.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/incoming_call_dialog.dart';
import 'socket_service.dart';

class ZegoCallService {

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
  static String generateRoomId(String orderId, {String? driverId, String? userId}) {
    if (driverId != null && userId != null) {
      return "order_${orderId}_${driverId}_${userId}";
    }
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
  static Future<void> handleIncomingCall({
    required BuildContext context,
    required String orderId,
    required String roomId,
    required String callerId,
    required String callerName,
  }) async {
    debugPrint('📞 Incoming call received: $callerName calling for order $orderId');
    
    // Get current user info
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
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
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => IncomingCallDialog(
          callerName: callerName,
          orderId: orderId,
          roomId: roomId,
          callerId: callerId,
          onAccept: () => _acceptCall(
            context: dialogContext,
            orderId: orderId,
            roomId: roomId,
            callerId: callerId,
            callerName: callerName,
          ),
          onReject: () => _rejectCall(
            context: dialogContext,
            orderId: orderId,
            roomId: roomId,
            callerId: callerId,
          ),
        ),
      );
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
    
    // Check microphone permission
    final hasPermission = await checkMicrophonePermission();
    if (!hasPermission) {
      showPermissionError(context);
      return;
    }
    
    // Notify caller that call was accepted
    SocketService.emit('call-accepted', {
      'orderId': orderId,
      'roomId': roomId,
      'callerId': callerId,
      'receiverId': userId,
    });
    
    // Fetch token for the receiver
    final tokenData = await fetchToken(
      userId: userId,
      userName: userName,
      roomId: roomId,
    );
    
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
    
    // Navigate to call screen - receiver joins the same room
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ZegoUIKitPrebuiltCall(
            appID: appID,
            token: token,
            userID: userId,
            userName: userName,
            callID: roomId,
            config: ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
          ),
        ),
      );
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

    // Check microphone permission
    final hasPermission = await checkMicrophonePermission();
    if (!hasPermission) {
      showPermissionError(context);
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Generate room ID
      final roomId = generateRoomId(orderId, driverId: driverId, userId: userId);
      debugPrint('Starting call with roomId: $roomId, userId: $userId, userName: $userName');

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

      // Notify receiver via Socket.IO before starting call
      if (driverId != null || customerId != null) {
        final receiverId = driverId ?? customerId;
        if (receiverId != null && receiverId.isNotEmpty) {
          debugPrint('Sending call notification to receiver: $receiverId');
          
          // Set up listener for call rejection/timeout
          bool callAccepted = false;
          bool callRejected = false;
          
          void onCallAccepted(dynamic data) {
            if (data['roomId'] == roomId && data['callerId'] == userId) {
              callAccepted = true;
              SocketService.off('call-accepted');
              SocketService.off('call-rejected');
              debugPrint('✅ Call accepted by receiver');
            }
          }
          
          void onCallRejected(dynamic data) {
            if (data['roomId'] == roomId && data['callerId'] == userId) {
              callRejected = true;
              SocketService.off('call-accepted');
              SocketService.off('call-rejected');
              debugPrint('❌ Call rejected by receiver');
              
              if (context.mounted) {
                Navigator.of(context).pop(); // Close loading dialog
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
          
          // Set timeout for call acceptance (30 seconds)
          Timer(const Duration(seconds: 30), () {
            if (!callAccepted && !callRejected && context.mounted) {
              SocketService.off('call-accepted');
              SocketService.off('call-rejected');
              Navigator.of(context).pop(); // Close loading dialog
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ZegoUIKitPrebuiltCall(
              appID: appID,
              token: token,
              userID: userId,
              userName: userName,
              callID: roomId,
              config: ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
            ),
          ),
        ).then((_) {
          // Clean up listeners when call screen is closed
          SocketService.off('call-accepted');
          SocketService.off('call-rejected');
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

