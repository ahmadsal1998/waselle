import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/api_service.dart';

class LocationProvider with ChangeNotifier {
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
        _errorMessage = 'Please enable location access to display your current position on the map.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).catchError((error) {
        debugPrint('Error getting current position: $error');
        _errorMessage = 'Failed to get your location. Please check your GPS settings.';
        return null;
      });

      if (_currentPosition == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Build address string with available components
          List<String> addressParts = [];
          if (place.street != null && place.street!.isNotEmpty) {
            addressParts.add(place.street!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }
          
          if (addressParts.isNotEmpty) {
            _currentAddress = addressParts.join(', ');
          } else {
            _currentAddress = '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}';
          }
        } else {
          _currentAddress = '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}';
        }
      } catch (e) {
        debugPrint('Error getting address: $e');
        // Fallback to coordinates if geocoding fails
        _currentAddress = '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}';
      }

      // Update location on server
      try {
        await ApiService.updateLocation(
          lat: _currentPosition!.latitude,
          lng: _currentPosition!.longitude,
        );
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
              Placemark place = placemarks[0];
              // Build address string with available components
              List<String> addressParts = [];
              if (place.street != null && place.street!.isNotEmpty) {
                addressParts.add(place.street!);
              }
              if (place.subLocality != null && place.subLocality!.isNotEmpty) {
                addressParts.add(place.subLocality!);
              }
              if (place.locality != null && place.locality!.isNotEmpty) {
                addressParts.add(place.locality!);
              }
              if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
                addressParts.add(place.administrativeArea!);
              }
              if (place.country != null && place.country!.isNotEmpty) {
                addressParts.add(place.country!);
              }
              
              if (addressParts.isNotEmpty) {
                _currentAddress = addressParts.join(', ');
              } else {
                _currentAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
              }
              notifyListeners();
            } else {
              _currentAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
              notifyListeners();
            }
          }).catchError((e) {
            debugPrint('Error getting address in stream: $e');
            // Fallback to coordinates if geocoding fails
            _currentAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
            notifyListeners();
          });
          
          // Update location on server
          ApiService.updateLocation(
            lat: position.latitude,
            lng: position.longitude,
          ).catchError((error) {
            debugPrint('Error updating location on server: $error');
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

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}
