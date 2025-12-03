import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/api_service.dart';
import '../services/socket_service.dart';
import '../services/review_mode_service.dart';
import '../services/review_mode_mock_data.dart';

class DriverViewModel with ChangeNotifier {
  List<Map<String, dynamic>> _drivers = [];
  bool _isLoading = false;
  bool _socketListenersAttached = false;

  List<Map<String, dynamic>> get drivers => _drivers;
  bool get isLoading => _isLoading;

  Future<void> fetchDrivers() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if Review Mode is active
      final isReviewMode = await ReviewModeService.isReviewModeActive();
      if (isReviewMode) {
        // Use mock drivers for Review Mode
        _drivers = List<Map<String, dynamic>>.from(ReviewModeMockData.testDriverLocations);
        debugPrint('🍎 Review Mode: Using mock drivers');
        return;
      }
      
      // Check if authenticated before fetching drivers
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        // Not authenticated, don't fetch drivers
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final response = await ApiService.getAvailableDrivers();
      if (response['drivers'] != null) {
        _drivers = List<Map<String, dynamic>>.from(response['drivers']);
      }
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void attachSocketListeners() {
    if (_socketListenersAttached) return;

    SocketService.on('driver-location-update', (data) {
      if (data == null ||
          data['driverId'] == null ||
          data['location'] == null) {
        return;
      }

      final driverId = data['driverId'];
      final location = data['location'] as Map<String, dynamic>;
      final lat = _parseToDouble(location['lat']);
      final lng = _parseToDouble(location['lng']);

      if (lat == null || lng == null) return;

      final index = _drivers.indexWhere((driver) => driver['_id'] == driverId);
      if (index != -1) {
        _drivers[index] = {
          ..._drivers[index],
          'location': {'lat': lat, 'lng': lng},
        };
      } else {
        _drivers.add({
          '_id': driverId,
          'location': {'lat': lat, 'lng': lng},
          'isAvailable': true,
        });
      }
      notifyListeners();
    });

    _socketListenersAttached = true;
  }

  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  void dispose() {
    if (_socketListenersAttached) {
      SocketService.off('driver-location-update');
    }
    super.dispose();
  }
}
