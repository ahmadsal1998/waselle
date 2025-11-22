import '../utils/api_client.dart';

class UserRepository {
  Future<Map<String, dynamic>> updateLocation({
    required double lat,
    required double lng,
  }) async {
    final response = await ApiClient.patch(
      '/users/location',
      body: {
        'lat': lat,
        'lng': lng,
      },
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>> updateAvailability({
    required bool isAvailable,
  }) async {
    final response = await ApiClient.patch(
      '/users/availability',
      body: {
        'isAvailable': isAvailable,
      },
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>> updateProfilePicture({
    required String profilePictureUrl,
  }) async {
    final response = await ApiClient.patch(
      '/users/profile-picture',
      body: {
        'profilePicture': profilePictureUrl,
      },
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>> getMyBalance() async {
    final response = await ApiClient.get('/users/balance');
    return _asMap(response);
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw const FormatException('Unexpected response format');
  }
}

