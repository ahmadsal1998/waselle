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
        debugPrint('Cannot get location: permission not granted');
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

      await _userRepository.updateLocation(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Handle specific location errors
      if (e.toString().contains('LocationUnknown') || 
          e.toString().contains('kCLErrorLocationUnknown')) {
        debugPrint('Location unknown error. Please check:');
        debugPrint('1. Location services are enabled in Settings');
        debugPrint('2. App has location permissions');
        debugPrint('3. If using simulator, set a location in Features > Location');
      }
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
      (position) {
        _currentPosition = position;
        _userRepository.updateLocation(
          lat: position.latitude,
          lng: position.longitude,
        );
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
        if (error.toString().contains('LocationUnknown') || 
            error.toString().contains('kCLErrorLocationUnknown')) {
          debugPrint('Location unknown error in stream. Please check:');
          debugPrint('1. Location services are enabled in Settings');
          debugPrint('2. App has location permissions');
          debugPrint('3. If using simulator, set a location in Features > Location');
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

