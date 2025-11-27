import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class ApiClient {
  //static const String baseUrl = 'http://localhost:5001/api';
  static const String baseUrl = 'https://waselle.onrender.com/api';

  static String get socketUrl => baseUrl.replaceAll('/api', '');

  static Future<Map<String, String>> _buildHeaders({
    Map<String, String>? additionalHeaders,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?additionalHeaders,
    };
  }

  static Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
    final response = await http.get(
      uri,
      headers: await _buildHeaders(additionalHeaders: headers),
    );
    return _decodeResponse(response);
  }

  static Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _buildHeaders(additionalHeaders: headers),
      body: body != null ? jsonEncode(body) : null,
    );
    return _decodeResponse(response);
  }

  static Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _buildHeaders(additionalHeaders: headers),
      body: body != null ? jsonEncode(body) : null,
    );
    return _decodeResponse(response);
  }

  static Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _buildHeaders(additionalHeaders: headers),
      body: body != null ? jsonEncode(body) : null,
    );
    return _decodeResponse(response);
  }

  static dynamic _decodeResponse(http.Response response) {
    dynamic decodedBody;
    if (response.body.isNotEmpty) {
      try {
        decodedBody = jsonDecode(response.body);
      } catch (_) {
        decodedBody = response.body;
      }
    }

    final statusCode = response.statusCode;
    final isSuccess = statusCode >= 200 && statusCode < 300;
    
    if (!isSuccess) {
      // Handle 401 Unauthorized - clear token for re-authentication
      if (statusCode == 401) {
        // Clear token from storage to force re-authentication
        SharedPreferences.getInstance().then((prefs) {
          prefs.remove('token');
        });
      }
      
      // Handle 403 Forbidden - check if it's due to suspension
      if (statusCode == 403) {
        String? errorMessage;
        if (decodedBody is Map<String, dynamic>) {
          errorMessage = decodedBody['message']?.toString();
        }
        
        // Check if error message indicates suspension
        if (errorMessage != null && 
            (errorMessage.toLowerCase().contains('suspended') || 
             errorMessage.toLowerCase().contains('deactivated'))) {
          _navigateToSuspendedScreen();
        }
      }
      
      // Extract error message from response body if available
      String? errorMessage;
      if (decodedBody is Map<String, dynamic>) {
        errorMessage = decodedBody['message']?.toString();
      }
      
      throw ApiException(
        statusCode: statusCode,
        body: decodedBody,
        message: errorMessage ?? 'Request failed with status $statusCode',
      );
    }

    // Check for suspension status in successful responses that contain user data
    _checkUserStatusInResponse(decodedBody);

    return decodedBody;
  }

  /// Check if user data in response indicates suspension and navigate if needed
  static void _checkUserStatusInResponse(dynamic decodedBody) {
    if (decodedBody is Map<String, dynamic>) {
      // Check if response contains user data
      final user = decodedBody['user'];
      if (user is Map<String, dynamic>) {
        final isActive = user['isActive'];
        final role = user['role'];
        
        // If driver and account is inactive, navigate to suspended screen
        if (role == 'driver' && isActive == false) {
          _navigateToSuspendedScreen();
        }
      }
      
      // Also check if response itself is user data (like /auth/me)
      final isActive = decodedBody['isActive'];
      final role = decodedBody['role'];
      if (role == 'driver' && isActive == false) {
        _navigateToSuspendedScreen();
      }
    }
  }

  /// Navigate to suspended screen if not already there
  static void _navigateToSuspendedScreen() {
    final navigatorKey = GlobalNavigatorKey.navigatorKey;
    if (navigatorKey?.currentContext != null) {
      try {
        final currentRoute = ModalRoute.of(navigatorKey!.currentContext!);
        final currentRouteName = currentRoute?.settings.name;
        
        // Only navigate if not already on suspended screen
        if (currentRouteName != '/suspended') {
          // Use SchedulerBinding to ensure navigation happens in the right frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (navigatorKey.currentContext != null) {
              try {
                final currentRoute = ModalRoute.of(navigatorKey.currentContext!);
                final currentRouteName = currentRoute?.settings.name;
                if (currentRouteName != '/suspended') {
                  Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
                    '/suspended',
                    (route) => false,
                  );
                }
              } catch (_) {
                // Navigation failed, ignore
              }
            }
          });
        }
      } catch (e) {
        // If navigation fails, ignore to prevent loops
      }
    }
  }

  /// Get legal URLs (Privacy Policy and Terms of Service)
  static Future<Map<String, String>> getLegalUrls() async {
    try {
      final response = await get('/settings/legal-urls');
      if (response is Map<String, dynamic>) {
        return {
          'privacyPolicyUrl': response['privacyPolicyUrl'] as String? ?? 'https://www.wassle.ps/privacy-policy',
          'termsOfServiceUrl': response['termsOfServiceUrl'] as String? ?? 'https://www.wassle.ps/terms-of-service',
        };
      }
      // Return default URLs if response format is unexpected
      return {
        'privacyPolicyUrl': 'https://www.wassle.ps/privacy-policy',
        'termsOfServiceUrl': 'https://www.wassle.ps/terms-of-service',
      };
    } catch (e) {
      // Return default URLs if API fails
      return {
        'privacyPolicyUrl': 'https://www.wassle.ps/privacy-policy',
        'termsOfServiceUrl': 'https://www.wassle.ps/terms-of-service',
      };
    }
  }
}

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    this.body,
    this.message,
  });

  final int statusCode;
  final dynamic body;
  final String? message;

  @override
  String toString() {
    final buffer = StringBuffer('ApiException(statusCode: $statusCode');
    if (message != null) {
      buffer.write(', message: $message');
    }
    if (body != null) {
      buffer.write(', body: $body');
    }
    buffer.write(')');
    return buffer.toString();
  }
}

