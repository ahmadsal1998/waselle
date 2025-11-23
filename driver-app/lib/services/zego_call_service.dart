import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../utils/api_client.dart';

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
    try {
      final response = await ApiClient.post(
        '/zego/token',
        body: {
          'userId': userId,
          'userName': userName,
          'roomId': roomId,
        },
      );
      
      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching Zego token: $e');
      return null;
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
              content: Text('Failed to start call. Please try again.'),
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

      // Navigate to call screen using token
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
          // Handle when call screen is closed
          // This will be called when user navigates back from call screen
        });
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting call: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

