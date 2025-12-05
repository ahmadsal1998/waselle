import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart';

/// Service to manage review mode detection and state
/// Review mode is activated when the app is being reviewed by Apple (App Review / TestFlight)
class ReviewModeService {
  static const String _reviewModeKey = 'is_review_mode';
  static const String _reviewModeCheckedKey = 'review_mode_checked';
  
  static bool _isReviewMode = false;
  static bool _isChecked = false;
  
  /// Check if review mode is currently active
  static bool get isReviewMode => _isReviewMode;
  
  /// Check if review mode has been checked
  static bool get isChecked => _isChecked;
  
  /// Initialize review mode check
  /// This should be called at app startup
  static Future<void> initialize() async {
    if (_isChecked) {
      debugPrint('ReviewModeService: Already checked, using cached value: $_isReviewMode');
      return;
    }
    
    try {
      debugPrint('ReviewModeService: Checking review mode status...');
      
      // Load cached value first (for offline support)
      final prefs = await SharedPreferences.getInstance();
      final cachedMode = prefs.getBool(_reviewModeKey);
      if (cachedMode != null) {
        _isReviewMode = cachedMode;
        _isChecked = true;
        debugPrint('ReviewModeService: Using cached review mode: $_isReviewMode');
      }
      
      // Check with backend
      try {
        final response = await ApiClient.get('/review-mode');
        if (response is Map<String, dynamic>) {
          final mode = response['mode'] as String?;
          _isReviewMode = mode == 'review';
          _isChecked = true;
          
          // Cache the result
          await prefs.setBool(_reviewModeKey, _isReviewMode);
          await prefs.setBool(_reviewModeCheckedKey, true);
          
          debugPrint('ReviewModeService: Review mode status from backend: $_isReviewMode');
        }
      } catch (e) {
        debugPrint('ReviewModeService: Error checking review mode: $e');
        // Use cached value if available, otherwise default to false
        if (cachedMode == null) {
          _isReviewMode = false;
          _isChecked = true;
        }
      }
    } catch (e) {
      debugPrint('ReviewModeService: Error initializing: $e');
      _isReviewMode = false;
      _isChecked = true;
    }
  }
  
  /// Force refresh review mode status from backend
  static Future<void> refresh() async {
    _isChecked = false;
    await initialize();
  }
  
  /// Clear cached review mode status
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reviewModeKey);
    await prefs.remove(_reviewModeCheckedKey);
    _isReviewMode = false;
    _isChecked = false;
  }
  
  /// Get fake driver credentials for review mode
  static Map<String, String> getReviewCredentials() {
    return {
      'email': 'review@driver.test',
      'password': 'review123',
    };
  }
  
  /// Get mock orders for review mode
  static List<Map<String, dynamic>> getMockOrders() {
    return [
      {
        '_id': 'TEST1',
        'id': 'TEST1',
        'pickup': 'Demo Restaurant',
        'dropoff': 'Demo Area 1',
        'price': 5.0,
        'estimatedPrice': 5.0,
        'distance': 2.4,
        'distanceFromDriver': 2.4,
        'status': 'pending',
        'type': 'send',
        'vehicleType': 'bike',
        'deliveryType': 'internal',
        'orderCategory': 'Food',
        'senderName': 'Demo Customer 1',
        'pickupLocation': {
          'lat': 31.9522,
          'lng': 35.2332,
        },
        'dropoffLocation': {
          'lat': 31.9622,
          'lng': 35.2432,
        },
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        '_id': 'TEST2',
        'id': 'TEST2',
        'pickup': 'Demo Market',
        'dropoff': 'Demo Neighborhood',
        'price': 7.0,
        'estimatedPrice': 7.0,
        'distance': 3.1,
        'distanceFromDriver': 3.1,
        'status': 'pending',
        'type': 'send',
        'vehicleType': 'bike',
        'deliveryType': 'internal',
        'orderCategory': 'Groceries',
        'senderName': 'Demo Customer 2',
        'pickupLocation': {
          'lat': 31.9522,
          'lng': 35.2332,
        },
        'dropoffLocation': {
          'lat': 31.9722,
          'lng': 35.2532,
        },
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];
  }
}

