import '../utils/api_client.dart';

class AuthRepository {
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    required String vehicleType,
  }) async {
    final response = await ApiClient.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'role': 'driver',
        'vehicleType': vehicleType,
      },
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await ApiClient.post(
      '/auth/verify-otp',
      body: {
        'email': email,
        'otp': otp,
      },
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>> verifyFirebaseToken({
    required String idToken,
    required String phoneNumber,
  }) async {
    final response = await ApiClient.post(
      '/auth/verify-firebase-token',
      body: {
        'idToken': idToken,
        'phoneNumber': phoneNumber,
      },
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await ApiClient.get('/auth/me');
    return _asMap(response);
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw const FormatException('Unexpected response format');
  }
}

