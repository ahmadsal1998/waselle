import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../services/api_service.dart';

class LocationProvider with ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  Future<bool>? _permissionRequest;
  StreamSubscription<Position>? _positionSubscription;
  bool _hasLocationPermission = false;

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;

  Future<bool> requestLocationPermission() async {
    _permissionRequest ??= _handlePermissionRequest();
    final granted = await _permissionRequest!;
    _hasLocationPermission = granted;
    _permissionRequest = null;
    return granted;
  }

  Future<bool> _handlePermissionRequest() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return;

      if (!_hasLocationPermission) return;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          _currentAddress =
              '${place.street}, ${place.locality}, ${place.country}';
        }
      } catch (e) {
        _currentAddress = 'Unable to get address';
      }

      // Update location on server
      await ApiService.updateLocation(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> startLocationUpdates() async {
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) return;

    await _positionSubscription?.cancel();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) {
      _currentPosition = position;
      ApiService.updateLocation(
        lat: position.latitude,
        lng: position.longitude,
      );
      notifyListeners();
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }
}
