import '../utils/api_client.dart';

class RegionRepository {
  Future<List<Map<String, dynamic>>> getCities({
    bool activeOnly = true,
  }) async {
    final response = await ApiClient.get(
      '/cities',
      queryParameters: activeOnly ? {'active': 'true'} : null,
    );
    if (response is Map<String, dynamic>) {
      final cities = response['cities'];
      if (cities is List) {
        return List<Map<String, dynamic>>.from(cities);
      }
      return const [];
    }
    throw const FormatException('Unexpected response format');
  }

  Future<List<Map<String, dynamic>>> getVillages(
    String cityId, {
    bool activeOnly = true,
  }) async {
    final queryParameters = <String, String>{'cityId': cityId};
    if (activeOnly) {
      queryParameters['active'] = 'true';
    }

    final response = await ApiClient.get(
      '/villages',
      queryParameters: queryParameters,
    );

    if (response is Map<String, dynamic>) {
      final villages = response['villages'];
      if (villages is List) {
        return List<Map<String, dynamic>>.from(villages);
      }
      return const [];
    }

    throw const FormatException('Unexpected response format');
  }
}

