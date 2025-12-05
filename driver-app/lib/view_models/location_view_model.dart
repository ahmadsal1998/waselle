import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../repositories/user_repository.dart';

class LocationViewModel with ChangeNotifier {
  LocationViewModel({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  final UserRepository _userRepository;

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
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled. Please enable location services in Settings.');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied by user.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission denied forever. Please enable in Settings.');
      return false;
    }

    return true;
  }

  Future<void> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission || !_hasLocationPermission) {
        debugPrint('Location permission not granted - app will continue without location updates');
        // Don't block the app - just skip location updates
        notifyListeners();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      try {
        final placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _currentAddress =
              '${place.street}, ${place.locality}, ${place.country}';
        }
      } catch (e) {
        _currentAddress = 'Unable to get address';
        debugPrint('Error resolving address: $e');
      }

      // Only update location on backend if we have valid coordinates
      if (_currentPosition != null) {
        try {
          await _userRepository.updateLocation(
            lat: _currentPosition!.latitude,
            lng: _currentPosition!.longitude,
          );
        } catch (e) {
          debugPrint('Error updating location on backend: $e');
          // Don't block the app if location update fails
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Don't block the app - just log the error and continue
      // Handle specific location errors
      if (e.toString().contains('LocationUnknown') || 
          e.toString().contains('kCLErrorLocationUnknown')) {
        debugPrint('Location unknown error. App will continue without location.');
      }
      notifyListeners();
    }
  }

  Future<void> startLocationUpdates() async {
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      debugPrint('Location permission not granted - skipping location updates');
      // Don't block the app - just skip location updates
      return;
    }

    await _positionSubscription?.cancel();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (position) {
        _currentPosition = position;
        // Update location on backend, but don't block if it fails
        _userRepository.updateLocation(
          lat: position.latitude,
          lng: position.longitude,
        ).catchError((error) {
          debugPrint('Error updating location on backend: $error');
          // Don't block the app if location update fails
        });
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
        // Don't block the app - just log the error
        if (error.toString().contains('LocationUnknown') || 
            error.toString().contains('kCLErrorLocationUnknown')) {
          debugPrint('Location unknown error in stream. App will continue without location updates.');
        }
      },
    );
  }

  Future<void> stopLocationUpdates() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

