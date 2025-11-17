import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/api_service.dart';

class LocationViewModel with ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  StreamSubscription<Position>? _positionStreamSubscription;
  String? _errorMessage;
  bool _isLoading = false;

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        _errorMessage =
            'Please enable location access to display your current position on the map.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (error) {
        debugPrint('Error getting current position: $error');
        _errorMessage =
            'Failed to get your location. Please check your GPS settings.';
        _currentPosition = null;
      }

      if (_currentPosition == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get address from coordinates
      try {
        final placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        if (placemarks.isNotEmpty) {
          _currentAddress = _formatPlacemarkAddress(
            placemarks.first,
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
        } else {
          _currentAddress = _coordinateLabel(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
        }
      } catch (e) {
        debugPrint('Error getting address: $e');
        // Fallback to coordinates if geocoding fails
        _currentAddress = _coordinateLabel(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }

      // Update location on server only if authenticated
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          await ApiService.updateLocation(
            lat: _currentPosition!.latitude,
            lng: _currentPosition!.longitude,
          );
        }
      } catch (e) {
        debugPrint('Error updating location on server: $e');
        // Don't fail the whole operation if server update fails
      }

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting location: $e');
      _errorMessage = 'An error occurred while getting your location: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void startLocationUpdates() {
    // Cancel existing subscription if any
    stopLocationUpdates();

    requestLocationPermission().then((hasPermission) {
      if (!hasPermission) {
        debugPrint('Cannot start location updates: permission not granted');
        return;
      }

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).handleError((error) {
        // Handle errors gracefully without crashing
        debugPrint('Error in location stream: $error');
        // Don't throw the error, just log it
      }).listen(
        (Position position) {
          _currentPosition = position;

          // Update address when location changes (async operation)
          placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).then((placemarks) {
            if (placemarks.isNotEmpty) {
              _currentAddress = _formatPlacemarkAddress(
                placemarks.first,
                position.latitude,
                position.longitude,
              );
              notifyListeners();
            } else {
              _currentAddress = _coordinateLabel(
                position.latitude,
                position.longitude,
              );
              notifyListeners();
            }
          }).catchError((e) {
            debugPrint('Error getting address in stream: $e');
            // Fallback to coordinates if geocoding fails
            _currentAddress = _coordinateLabel(
              position.latitude,
              position.longitude,
            );
            notifyListeners();
          });

          // Update location on server only if authenticated
          SharedPreferences.getInstance().then((prefs) {
            final token = prefs.getString('token');
            if (token != null) {
              ApiService.updateLocation(
                lat: position.latitude,
                lng: position.longitude,
              ).catchError((error) {
                debugPrint('Error updating location on server: $error');
                return <String, dynamic>{};
              });
            }
          }).catchError((error) {
            debugPrint('Error checking auth for location update: $error');
          });
          notifyListeners();
        },
        onError: (error) {
          // This should not be called if handleError is used, but keep it as backup
          debugPrint('Error in location stream listener: $error');
        },
        cancelOnError: false, // Continue listening even after errors
      );
    }).catchError((error) {
      debugPrint('Error starting location updates: $error');
    });
  }

  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  String _coordinateLabel(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String _formatPlacemarkAddress(
    Placemark place,
    double latitude,
    double longitude,
  ) {
    final parts = <String>[
      if (place.street?.isNotEmpty ?? false) place.street!,
      if (place.subLocality?.isNotEmpty ?? false) place.subLocality!,
      if (place.locality?.isNotEmpty ?? false) place.locality!,
      if (place.administrativeArea?.isNotEmpty ?? false)
        place.administrativeArea!,
      if (place.country?.isNotEmpty ?? false) place.country!,
    ];

    if (parts.isEmpty) {
      return _coordinateLabel(latitude, longitude);
    }
    return parts.join(', ');
  }

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}
