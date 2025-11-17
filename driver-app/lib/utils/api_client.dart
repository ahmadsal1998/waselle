import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:5001/api';

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

    return decodedBody;
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

