import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Configure your backend URL here
  // For local development: 'http://localhost:5001/api'
  // For Android emulator: 'http://10.0.2.2:5001/api'
  // For iOS simulator: 'http://localhost:5001/api'
  // For production: 'https://your-backend-url.com/api'
  //static const String baseUrl = 'http://localhost:5001/api';
  static const String baseUrl = 'https://waselle.onrender.com/api';

  // Get the base URL for socket connections (without /api)
  // For Render.com, socket URL should be the same as base URL without /api
  static String get socketUrl {
    final url = baseUrl.replaceAll('/api', '');
    // Ensure no trailing slash
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper method to safely parse JSON response
  static Map<String, dynamic> _parseResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw Exception(
          'Empty response from server. Status: ${response.statusCode}. Make sure the backend server is running on port 5001.');
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        throw Exception(
            'Invalid response format from server. Expected JSON object but got: ${decoded.runtimeType}');
      }
    } on FormatException catch (e) {
      // Include first 100 chars of response for debugging
      final preview = response.body.length > 100
          ? '${response.body.substring(0, 100)}...'
          : response.body;
      throw Exception(
          'Invalid JSON response from server. Status: ${response.statusCode}. Error: ${e.message}. Response preview: $preview');
    }
  }

  // Auth
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'role': 'customer',
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        // Try to parse error response
        try {
          final responseData = _parseResponse(response);
          throw Exception(responseData['message'] ?? 'Registration failed');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception(
              'Registration failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is http.ClientException ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
            'Unable to connect to server. Please check your internet connection or ensure the backend server is running on port 5001.');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        try {
          final responseData = _parseResponse(response);
          throw Exception(responseData['message'] ?? 'Login failed');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Login failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is http.ClientException ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
            'Unable to connect to server. Please check your internet connection or ensure the backend server is running on port 5001.');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        try {
          final responseData = _parseResponse(response);
          throw Exception(responseData['message'] ?? 'OTP verification failed');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception(
              'OTP verification failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is http.ClientException ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
            'Unable to connect to server. Please check your internet connection or ensure the backend server is running on port 5001.');
      }
      rethrow;
    }
  }

  // Send OTP to phone number via SMS provider (replaces Firebase)
  static Future<Map<String, dynamic>> sendPhoneOTP({
    required String phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-phone-otp'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        try {
          final responseData = _parseResponse(response);
          throw Exception(responseData['message'] ?? 'Failed to send OTP');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception(
              'Failed to send OTP with status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is http.ClientException ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
            'Unable to connect to server. Please check your internet connection or ensure the backend server is running on port 5001.');
      }
      rethrow;
    }
  }

  // Verify phone OTP (replaces Firebase verification)
  static Future<Map<String, dynamic>> verifyPhoneOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-phone-otp'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'otp': otp,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = _parseResponse(response);
        
        // Store JWT token if provided
        if (responseData['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token'] as String);
        }
        
        return responseData;
      } else {
        try {
          final responseData = _parseResponse(response);
          throw Exception(responseData['message'] ?? 'OTP verification failed');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception(
              'OTP verification failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is http.ClientException ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
            'Unable to connect to server. Please check your internet connection or ensure the backend server is running on port 5001.');
      }
      rethrow;
    }
  }

  // Verify Firebase ID token with backend (DEPRECATED - kept for backward compatibility)
  static Future<Map<String, dynamic>> verifyFirebaseToken({
    required String idToken,
    required String phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-firebase-token'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'idToken': idToken,
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        try {
          final responseData = _parseResponse(response);
          throw Exception(responseData['message'] ?? 'Firebase token verification failed');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception(
              'Firebase token verification failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is http.ClientException ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
            'Unable to connect to server. Please check your internet connection or ensure the backend server is running on port 5001.');
      }
      rethrow;
    }
  }

  // Phone login - creates/updates user in MongoDB after Firebase verification
  static Future<Map<String, dynamic>> phoneLogin({
    required String phone,
    required String firebaseUid,
    required String verificationId,
    required String smsCode,
    String? idToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/phone-login'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'phone': phone,
          'firebaseUid': firebaseUid,
          'verificationId': verificationId,
          'smsCode': smsCode,
          if (idToken != null) 'idToken': idToken,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = _parseResponse(response);
        
        // Store JWT token if provided
        if (responseData['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token'] as String);
        }
        
        return responseData;
      } else {
        try {
          final responseData = _parseResponse(response);
          throw Exception(responseData['message'] ?? 'Phone login failed');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Phone login failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is http.ClientException ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
            'Unable to connect to server. Please check your internet connection or ensure the backend server is running.');
      }
      rethrow;
    }
  }


  // Orders
  static Future<Map<String, dynamic>> createOrder({
    required String type,
    required String deliveryType,
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropoffLocation,
    required String vehicleType,
    required String orderCategory,
    required String senderName,
    required String senderCity,
    required String senderVillage,
    required String senderStreetDetails,
    required int senderPhoneNumber,
    String? deliveryNotes,
    double? estimatedPrice,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'type': type,
          'deliveryType': deliveryType,
          'pickupLocation': pickupLocation,
          'dropoffLocation': dropoffLocation,
          'vehicleType': vehicleType,
          'orderCategory': orderCategory,
          'senderName': senderName,
          'senderCity': senderCity,
          'senderVillage': senderVillage,
          'senderStreetDetails': senderStreetDetails,
          'senderPhoneNumber': senderPhoneNumber,
          if (deliveryNotes != null && deliveryNotes.isNotEmpty)
            'deliveryNotes': deliveryNotes,
          if (estimatedPrice != null) 'estimatedPrice': estimatedPrice,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        try {
          final responseData = _parseResponse(response);
          throw Exception(responseData['message'] ?? 'Failed to create order');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception(
              'Failed to create order with status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to create order: $e');
    }
  }

  static Future<Map<String, dynamic>> estimateOrderCost({
    required String vehicleType,
    Map<String, dynamic>? pickupLocation,
    Map<String, dynamic>? dropoffLocation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/estimate'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'vehicleType': vehicleType,
          if (pickupLocation != null) 'pickupLocation': pickupLocation,
          if (dropoffLocation != null) 'dropoffLocation': dropoffLocation,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        try {
          final responseData = _parseResponse(response);
          throw Exception(
            responseData['message'] ?? 'Failed to estimate delivery cost',
          );
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception(
            'Failed to estimate delivery cost with status ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to estimate delivery cost: $e');
    }
  }

  static Future<Map<String, dynamic>> getOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: await _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        throw Exception(
            'Failed to fetch orders with status ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to fetch orders: $e');
    }
  }

  static Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        throw Exception(
            'Failed to fetch order with status ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to fetch order: $e');
    }
  }

  // User
  static Future<Map<String, dynamic>> getAvailableDrivers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/drivers'),
        headers: await _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        throw Exception(
          'Failed to get available drivers with status ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to get available drivers: $e');
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        throw Exception(
            'Failed to get current user with status ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to get current user: $e');
    }
  }

  static Future<Map<String, dynamic>> updateLocation({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/location'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'lat': lat,
          'lng': lng,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        throw Exception(
            'Failed to update location with status ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to update location: $e');
    }
  }

  // Regions
  static Future<List<Map<String, dynamic>>> getCities({
    bool activeOnly = true,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl/cities');
      if (activeOnly) {
        uri = uri.replace(queryParameters: {'active': 'true'});
      }

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _parseResponse(response);
        final cities = data['cities'];
        if (cities is List) {
          return cities
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
        }
        throw Exception('Invalid response format for cities data.');
      } else {
        throw Exception(
          'Failed to fetch cities with status ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to fetch cities: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getVillages(
    String cityId, {
    bool activeOnly = true,
  }) async {
    try {
      if (cityId.isEmpty) {
        throw Exception('City id is required to fetch villages.');
      }

      Uri uri = Uri.parse('$baseUrl/villages');
      final queryParameters = <String, String>{'cityId': cityId};
      if (activeOnly) {
        queryParameters['active'] = 'true';
      }
      uri = uri.replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _parseResponse(response);
        final villages = data['villages'];
        if (villages is List) {
          return villages
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
        }
        throw Exception('Invalid response format for villages data.');
      } else {
        throw Exception(
          'Failed to fetch villages with status ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to fetch villages: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getOrderCategories({
    bool activeOnly = true,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl/order-categories');
      if (activeOnly) {
        uri = uri.replace(queryParameters: {'active': 'true'});
      }

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _parseResponse(response);
        final categories = data['categories'];
        if (categories is List) {
          return categories
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
        }
        throw Exception('Invalid response format for order categories data.');
      } else {
        throw Exception(
          'Failed to fetch order categories with status ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to fetch order categories: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getVehicleTypes() async {
    try {
      Uri uri = Uri.parse('$baseUrl/settings/vehicle-types');

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _parseResponse(response);
        final vehicleTypes = data['vehicleTypes'];
        if (vehicleTypes is List) {
          return vehicleTypes
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
        }
        throw Exception('Invalid response format for vehicle types data.');
      } else {
        throw Exception(
          'Failed to fetch vehicle types with status ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to fetch vehicle types: $e');
    }
  }

  // Send OTP via WhatsApp for order verification
  static Future<Map<String, dynamic>> sendOrderOTP({
    required String phone,
    required String countryCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/send-otp'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'phone': phone,
          'countryCode': countryCode,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        try {
          final responseData = _parseResponse(response);
          throw Exception(responseData['message'] ?? 'Failed to send OTP');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Failed to send OTP with status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to send OTP: $e');
    }
  }

  // Create order with Firebase ID token (recommended - uses Firebase Phone Auth)
  static Future<Map<String, dynamic>> createOrderWithFirebaseToken({
    required String idToken,
    required String type,
    required String deliveryType,
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropoffLocation,
    required String vehicleType,
    required String orderCategory,
    required String senderName,
    required String senderCity,
    required String senderVillage,
    required String senderStreetDetails,
    String? deliveryNotes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/create-with-firebase-token'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'idToken': idToken,
          'type': type,
          'deliveryType': deliveryType,
          'pickupLocation': pickupLocation,
          'dropoffLocation': dropoffLocation,
          'vehicleType': vehicleType,
          'orderCategory': orderCategory,
          'senderName': senderName,
          'senderCity': senderCity,
          'senderVillage': senderVillage,
          'senderStreetDetails': senderStreetDetails,
          if (deliveryNotes != null && deliveryNotes.isNotEmpty)
            'deliveryNotes': deliveryNotes,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        try {
          final responseData = _parseResponse(response);
          throw Exception(responseData['message'] ?? 'Failed to create order');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Failed to create order with status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to create order: $e');
    }
  }

  // Verify OTP and create order (DEPRECATED - use createOrderWithFirebaseToken instead)
  static Future<Map<String, dynamic>> verifyOTPAndCreateOrder({
    required String otp,
    required String phone,
    required String countryCode,
    required String type,
    required String deliveryType,
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropoffLocation,
    required String vehicleType,
    required String orderCategory,
    required String senderName,
    required String senderCity,
    required String senderVillage,
    required String senderStreetDetails,
    String? deliveryNotes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/verify-and-create'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'otp': otp,
          'phone': phone,
          'countryCode': countryCode,
          'type': type,
          'deliveryType': deliveryType,
          'pickupLocation': pickupLocation,
          'dropoffLocation': dropoffLocation,
          'vehicleType': vehicleType,
          'orderCategory': orderCategory,
          'senderName': senderName,
          'senderCity': senderCity,
          'senderVillage': senderVillage,
          'senderStreetDetails': senderStreetDetails,
          if (deliveryNotes != null && deliveryNotes.isNotEmpty)
            'deliveryNotes': deliveryNotes,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        try {
          final responseData = _parseResponse(response);
          throw Exception(responseData['message'] ?? 'Failed to verify OTP and create order');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception(
              'Failed to verify OTP and create order with status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to verify OTP and create order: $e');
    }
  }

  // Register FCM token for push notifications
  static Future<Map<String, dynamic>> registerFCMToken(String fcmToken) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/fcm-token'),
        headers: headers,
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        try {
          final responseData = _parseResponse(response);
          throw Exception(responseData['message'] ?? 'Failed to register FCM token');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Failed to register FCM token with status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to register FCM token: $e');
    }
  }

}
