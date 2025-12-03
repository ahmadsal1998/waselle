import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../repositories/home_repository.dart';

class DriverMarkerData {
  final LatLng position;
  final String? name;
  final bool isAvailable;

  const DriverMarkerData({
    required this.position,
    required this.name,
    required this.isAvailable,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DriverMarkerData) return false;
    return position.latitude == other.position.latitude &&
        position.longitude == other.position.longitude &&
        name == other.name &&
        isAvailable == other.isAvailable;
  }

  @override
  int get hashCode => Object.hash(
        position.latitude,
        position.longitude,
        name,
        isAvailable,
      );
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required this.repository}) {
    _registerListeners();
    _syncLocationState();
    _syncDriverState();
    _syncOrderState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      unawaited(initialize());
    });
  }

  final HomeRepository repository;
  final MapController mapController = MapController();

  LatLng? _currentLocation;
  LatLng? _lastCameraLocation;
  String? _locationErrorMessage;
  String? _currentAddress;
  List<DriverMarkerData> _driverMarkers = const [];
  bool _hasActiveOrder = false;
  bool _isBootstrapping = false;
  bool _hasInitialized = false;
  bool _isDisposed = false;
  int _currentTabIndex = 0;
  String? _initializationError;

  VoidCallback? _locationListener;
  VoidCallback? _driverListener;
  VoidCallback? _orderListener;

  LatLng? get currentLocation => _currentLocation;
  String? get currentAddress => _currentAddress;
  bool get hasActiveOrder => _hasActiveOrder;
  bool get isBootstrapping => _isBootstrapping;
  bool get isLocationLoading => repository.isLocationLoading;
  bool get isDriverLoading => repository.isDriverLoading;
  String? get locationErrorMessage => _locationErrorMessage;
  String? get initializationError => _initializationError;
  int get currentTabIndex => _currentTabIndex;

  List<DriverMarkerData> get driverMarkers => List.unmodifiable(_driverMarkers);

  // Only show initial loading briefly during bootstrapping
  // This prevents blocking the map - location errors are handled gracefully
  // We only show loading overlay for a very short time during actual bootstrap
  bool get isInitialLoading =>
      isBootstrapping &&
      _currentLocation == null &&
      _locationErrorMessage == null;

  bool get hasBlockingLocationError =>
      (_locationErrorMessage != null && _currentLocation == null) ||
      _initializationError != null;

  bool get showNoLocationState =>
      !isInitialLoading &&
      !hasBlockingLocationError &&
      _currentLocation == null;

  Future<void> initialize() async {
    if (_hasInitialized || _isDisposed) return;
    _hasInitialized = true;
    await _bootstrap();
  }

  Future<void> refreshAll() async {
    if (_isDisposed) return;
    await Future.wait([
      repository.refreshLocation(),
      repository.refreshDrivers(),
      repository.refreshOrders(),
    ]);
  }

  Future<void> retryLocation() async {
    if (_isDisposed) return;
    await repository.refreshLocation();
  }

  Future<void> refreshDrivers() async {
    if (_isDisposed) return;
    await repository.refreshDrivers();
  }

  void onTabSelected(int index) {
    if (_currentTabIndex == index || _isDisposed) return;
    _currentTabIndex = index;
    notifyListeners();
  }

  void recenterMap() {
    if (_isDisposed || _currentLocation == null) return;
    _moveCameraTo(_currentLocation!);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    repository.locationViewModel.removeListener(_locationListener ?? () {});
    repository.driverViewModel.removeListener(_driverListener ?? () {});
    repository.orderViewModel.removeListener(_orderListener ?? () {});
    repository.stopLocationUpdates();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _setBootstrapping(true);
    // Sync location state immediately (before waiting for location fetch)
    // This ensures we can show the map even if location is unavailable
    _syncLocationState();
    _notifySafely();
    
    try {
      // Start initialization in background - don't block on location
      // This allows the map to render immediately while location is being fetched
      unawaited(
        repository.initializeHome().catchError((error) {
          debugPrint('HomeViewModel initialization error: $error');
          // Don't set initialization error for location issues - they're non-blocking
          // Location errors are handled gracefully by showing default map location
        }),
      );
      _initializationError = null;
    } catch (error, stackTrace) {
      debugPrint('HomeViewModel bootstrap error: $error\n$stackTrace');
      // Only set initialization error for critical failures, not location issues
      if (!error.toString().toLowerCase().contains('location')) {
        _initializationError =
            'Failed to initialize home screen. Please try again.';
      }
    }
    
    // Mark bootstrapping as done immediately - don't wait for location
    // Location will update via listeners when it becomes available or fails
    _setBootstrapping(false);
    _syncLocationState();
    _syncDriverState();
    _syncOrderState();
    _notifySafely();
  }

  void _registerListeners() {
    _locationListener = () {
      final changed = _syncLocationState();
      if (changed) {
        _notifySafely();
      } else if (_currentAddress != repository.currentAddress) {
        _currentAddress = repository.currentAddress;
        _notifySafely();
      }
    };

    _driverListener = () {
      if (_syncDriverState()) {
        _notifySafely();
      }
    };

    _orderListener = () {
      if (_syncOrderState()) {
        _notifySafely();
      }
    };

    repository.locationViewModel.addListener(_locationListener!);
    repository.driverViewModel.addListener(_driverListener!);
    repository.orderViewModel.addListener(_orderListener!);
  }

  bool _syncLocationState() {
    final position = repository.currentPosition;
    final nextLocation =
        position != null ? LatLng(position.latitude, position.longitude) : null;
    final nextError = repository.locationErrorMessage;
    final nextAddress = repository.currentAddress;

    var hasChanged = false;
    if (_currentLocation?.latitude != nextLocation?.latitude ||
        _currentLocation?.longitude != nextLocation?.longitude) {
      _currentLocation = nextLocation;
      hasChanged = true;
      if (nextLocation != null && _shouldUpdateCamera(nextLocation)) {
        _lastCameraLocation = nextLocation;
        _moveCameraTo(nextLocation);
      }
    }

    if (_locationErrorMessage != nextError) {
      _locationErrorMessage = nextError;
      hasChanged = true;
    }

    if (_currentAddress != nextAddress) {
      _currentAddress = nextAddress;
      hasChanged = true;
    }

    return hasChanged;
  }

  bool _syncDriverState() {
    final data = repository.driverData;
    final updated = <DriverMarkerData>[];

    for (final driver in data) {
      final location = driver['location'];
      if (location is! Map<String, dynamic>) continue;

      final lat = _tryParse(location['lat']);
      final lng = _tryParse(location['lng']);
      if (lat == null || lng == null) continue;

      updated.add(
        DriverMarkerData(
          position: LatLng(lat, lng),
          name: driver['name']?.toString(),
          isAvailable: driver['isAvailable'] == true,
        ),
      );
    }

    if (!listEquals(_driverMarkers, updated)) {
      _driverMarkers = List.unmodifiable(updated);
      return true;
    }
    return false;
  }

  bool _syncOrderState() {
    final next = repository.hasActiveOrder;
    if (next != _hasActiveOrder) {
      _hasActiveOrder = next;
      return true;
    }
    return false;
  }

  double? _tryParse(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  bool _shouldUpdateCamera(LatLng nextLocation) {
    if (_lastCameraLocation == null) return true;
    const tolerance = 0.00001;
    final latDiff =
        (nextLocation.latitude - _lastCameraLocation!.latitude).abs();
    final lngDiff =
        (nextLocation.longitude - _lastCameraLocation!.longitude).abs();
    return latDiff > tolerance || lngDiff > tolerance;
  }

  void _moveCameraTo(LatLng location) {
    // Delay camera updates to the next frame to avoid setState issues.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      final zoom = mapController.camera.zoom;
      unawaited(
        Future<void>.delayed(Duration.zero, () {
          if (_isDisposed) return;
          mapController.move(location, zoom);
        }),
      );
    });
  }

  void _setBootstrapping(bool value) {
    if (_isBootstrapping == value || _isDisposed) return;
    _isBootstrapping = value;
    _notifySafely();
  }

  void _notifySafely() {
    if (_isDisposed) return;
    notifyListeners();
  }
}
