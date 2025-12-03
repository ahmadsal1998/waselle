import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Service for reverse geocoding using OpenStreetMap Nominatim API
/// Supports language-aware location names
class OSMGeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/reverse';
  
  // Cache to avoid repeated API calls for the same coordinates
  static final Map<String, String> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 24);

  /// Reverse geocode coordinates to get location name in the app's language
  /// 
  /// [lat] - Latitude
  /// [lng] - Longitude
  /// [context] - BuildContext to determine app language
  /// 
  /// Returns the location name in the app's language, or null if geocoding fails
  static Future<String?> reverseGeocode({
    required double lat,
    required double lng,
    required BuildContext context,
  }) async {
    // Get app language
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode; // 'ar' or 'en'
    
    // Create cache key with coordinates and language
    final cacheKey = '${lat.toStringAsFixed(6)}_${lng.toStringAsFixed(6)}_$languageCode';
    
    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _cache[cacheKey];
      } else {
        // Cache expired, remove it
        _cache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }

    try {
      // Build Nominatim API URL with language parameter
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'json',
        'accept-language': languageCode, // Set language based on app locale
        'addressdetails': '1',
        'zoom': '18', // Higher zoom for more specific location names
      });

      // Make request with proper User-Agent (required by Nominatim)
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'WassleUserApp/1.0', // Required by Nominatim
          'Accept-Language': languageCode,
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Geocoding request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Extract location name based on language
        // When accept-language is set, Nominatim returns address components in that language
        String? locationName;
        
        // First, try to get display_name (full address in requested language)
        final displayName = data['display_name']?.toString();
        if (displayName != null && displayName.isNotEmpty) {
          // Extract the most relevant part (usually the first part before comma)
          final parts = displayName.split(',');
          if (parts.isNotEmpty) {
            locationName = parts.first.trim();
          }
        }
        
        // If display_name didn't work, try the name field (location name in requested language)
        if ((locationName == null || locationName.isEmpty) && data['name'] != null) {
          locationName = data['name']?.toString();
        }
        
        // If still no name, try to extract from address components
        // These will be in the requested language when accept-language is set
        if (locationName == null || locationName.isEmpty) {
          final address = data['address'] as Map<String, dynamic>?;
          if (address != null) {
            // Try different address components in order of preference
            // These components will be in the requested language
            locationName = address['village']?.toString() ??
                          address['town']?.toString() ??
                          address['city']?.toString() ??
                          address['municipality']?.toString() ??
                          address['county']?.toString() ??
                          address['state']?.toString() ??
                          address['region']?.toString();
            
            // If we got a location name from address, try to add more context
            if (locationName != null && locationName.isNotEmpty) {
              // Optionally add street or road name if available
              final street = address['road']?.toString() ?? 
                           address['street']?.toString();
              if (street != null && street.isNotEmpty) {
                locationName = '$locationName, $street';
              }
            }
          }
        }

        if (locationName != null && locationName.isNotEmpty) {
          // Cache the result
          _cache[cacheKey] = locationName;
          _cacheTimestamps[cacheKey] = DateTime.now();
          return locationName;
        }
      } else if (response.statusCode == 429) {
        // Rate limit - return cached value if available, or null
        debugPrint('OSM Geocoding: Rate limit exceeded');
        return _cache[cacheKey];
      }
    } catch (e) {
      debugPrint('OSM Geocoding error: $e');
      // Return cached value if available
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey];
      }
    }

    return null;
  }

  /// Clear the geocoding cache
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Get location name from coordinates with fallback to stored address
  /// 
  /// This method tries OSM reverse geocoding first, then falls back to
  /// the stored address if geocoding fails or is not available
  static Future<String> getLocationName({
    required double? lat,
    required double? lng,
    required String? storedAddress,
    required BuildContext context,
  }) async {
    // If no coordinates, return stored address or fallback
    if (lat == null || lng == null) {
      return storedAddress ?? 'N/A';
    }

    // Try OSM reverse geocoding
    final osmName = await reverseGeocode(
      lat: lat,
      lng: lng,
      context: context,
    );

    // Return OSM name if available, otherwise fallback to stored address
    return osmName ?? storedAddress ?? 'N/A';
  }
}

