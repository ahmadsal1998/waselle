import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  // Using OSRM public demo server (you can replace with your own instance)
  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Get route between two points using OSRM
  /// Returns a list of LatLng points representing the route
  static Future<List<LatLng>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_osrmBaseUrl/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          
          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            return coordinates.map((coord) {
              // GeoJSON format is [lng, lat]
              return LatLng(coord[1].toDouble(), coord[0].toDouble());
            }).toList();
          }
        }
      }
      
      // Fallback: return straight line if routing fails
      return [
        LatLng(startLat, startLng),
        LatLng(endLat, endLng),
      ];
    } catch (e) {
      // Fallback: return straight line on error
      return [
        LatLng(startLat, startLng),
        LatLng(endLat, endLng),
      ];
    }
  }

  /// Get route distance in meters
  static Future<double?> getRouteDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_osrmBaseUrl/$startLng,$startLat;$endLng,$endLat?overview=false',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          return (route['distance'] as num).toDouble();
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get route duration in seconds
  static Future<double?> getRouteDuration({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_osrmBaseUrl/$startLng,$startLat;$endLng,$endLat?overview=false',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          return (route['duration'] as num).toDouble();
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}

