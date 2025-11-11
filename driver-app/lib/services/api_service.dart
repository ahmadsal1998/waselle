import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5001/api';
  static String get socketUrl => baseUrl.replaceAll('/api', '');
  // For production, use: 'https://your-backend-url.com/api'

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    required String vehicleType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'role': 'driver',
        'vehicleType': vehicleType,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );
    return jsonDecode(response.body);
  }

  // Orders
  static Future<Map<String, dynamic>> getAvailableOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/available'),
      headers: await _getHeaders(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/accept'),
      headers: await _getHeaders(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: await _getHeaders(),
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: await _getHeaders(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: await _getHeaders(),
    );
    return jsonDecode(response.body);
  }

  // User
  static Future<Map<String, dynamic>> updateLocation({
    required double lat,
    required double lng,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/location'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'lat': lat,
        'lng': lng,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateAvailability({
    required bool isAvailable,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/availability'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'isAvailable': isAvailable,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _getHeaders(),
    );
    return jsonDecode(response.body);
  }

  // Regions
  static Future<List<Map<String, dynamic>>> getCities({
    bool activeOnly = true,
  }) async {
    Uri uri = Uri.parse('$baseUrl/cities');
    if (activeOnly) {
      uri = uri.replace(queryParameters: {'active': 'true'});
    }

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['cities'] is List) {
        return List<Map<String, dynamic>>.from(data['cities'] as List);
      }
      return [];
    }

    throw Exception('Failed to fetch cities (${response.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> getVillages(
    String cityId, {
    bool activeOnly = true,
  }) async {
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
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['villages'] is List) {
        return List<Map<String, dynamic>>.from(data['villages'] as List);
      }
      return [];
    }

    throw Exception('Failed to fetch villages (${response.statusCode})');
  }
}
