import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../repositories/api_service.dart';
import '../services/socket_service.dart';
import '../utils/route_utils.dart';
import 'location_view_model.dart';
import 'order_view_model.dart';

class TrackedOrderState {
  TrackedOrderState({MapController? controller})
      : mapController = controller ?? MapController();

  final MapController mapController;

  LatLng? driverLocation;
  LatLng? customerLocation;
  List<LatLng> routePoints = const [];
  double? distanceMeters;
  bool isRouteLoading = false;
  DateTime? lastRouteRefresh;
  bool _isMapReady = false;
  LatLng? _pendingCenter;

  bool get isMapReady => _isMapReady;
  LatLng? get pendingCenter => _pendingCenter;

  void markMapReady() {
    _isMapReady = true;
    if (_pendingCenter != null) {
      try {
        mapController.move(_pendingCenter!, 13.0);
        _pendingCenter = null;
      } catch (e) {
        // Ignore errors if controller still not ready
      }
    }
  }

  void setPendingCenter(LatLng center) {
    _pendingCenter = center;
    if (_isMapReady) {
      try {
        mapController.move(center, 13.0);
        _pendingCenter = null;
      } catch (e) {
        // If move fails, keep it as pending
      }
    }
  }

  bool get hasBootstrapped =>
      driverLocation != null ||
      customerLocation != null ||
      routePoints.isNotEmpty ||
      distanceMeters != null;
}

class OrderTrackingViewModel extends ChangeNotifier {
  OrderTrackingViewModel({
    required this.orderViewModel,
    required this.locationViewModel,
    Duration routeRefreshThrottle = const Duration(seconds: 4),
  }) : _routeRefreshThrottle = routeRefreshThrottle;

  final OrderViewModel orderViewModel;
  final LocationViewModel locationViewModel;
  final Duration _routeRefreshThrottle;

  final Map<String, TrackedOrderState> _trackedOrders = {};
  final Map<String, Timer> _routeRefreshTimers = {};
  final Set<String> _bootstrappingOrders = <String>{};

  bool _isDisposed = false;
  bool _isInitialized = false;
  LatLng? _lastUserLocation;
  VoidCallback? _ordersListener;
  VoidCallback? _locationListener;
  void Function(dynamic)? _driverLocationListener;

  bool get isInitialized => _isInitialized;

  List<Map<String, dynamic>> get activeOrders => orderViewModel.activeOrders;

  TrackedOrderState? stateFor(String orderId) => _trackedOrders[orderId];

  LatLng? toLatLng(dynamic data) => _latLngFrom(data);

  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;
    _registerListeners();
    await _bootstrap();
    if (_isDisposed) return;
    _attachSocketListeners();
    _isInitialized = true;
    _notifySafely();
  }

  Future<void> refreshOrders() async {
    if (_isDisposed) return;
    await orderViewModel.fetchOrders();
    if (_isDisposed) return;
    _syncTrackedOrders(orderViewModel.activeOrders);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    if (_ordersListener != null) {
      orderViewModel.removeListener(_ordersListener!);
    }
    if (_locationListener != null) {
      locationViewModel.removeListener(_locationListener!);
    }
    for (final timer in _routeRefreshTimers.values) {
      timer.cancel();
    }
    _routeRefreshTimers.clear();
    if (_driverLocationListener != null) {
      SocketService.removeListener(
        'driver-location-update',
        _driverLocationListener!,
      );
    }
    super.dispose();
  }

  void _registerListeners() {
    _ordersListener = () {
      if (_isDisposed) return;
      _syncTrackedOrders(orderViewModel.activeOrders);
    };
    orderViewModel.addListener(_ordersListener!);

    _locationListener = () {
      if (_isDisposed) return;
      _maybeUpdateUserLocation();
    };
    locationViewModel.addListener(_locationListener!);
  }

  Future<void> _bootstrap() async {
    await _ensureOrdersLoaded();
    await _ensureLocationLoaded();
    if (_isDisposed) return;
    locationViewModel.startLocationUpdates();
    _syncTrackedOrders(orderViewModel.activeOrders);
    _maybeUpdateUserLocation();
  }

  Future<void> _ensureOrdersLoaded() async {
    if (orderViewModel.activeOrders.isNotEmpty) return;
    await orderViewModel.fetchOrders();
  }

  Future<void> _ensureLocationLoaded() async {
    if (locationViewModel.currentPosition != null ||
        locationViewModel.isLoading) {
      return;
    }
    await locationViewModel.getCurrentLocation();
  }

  void _syncTrackedOrders(List<Map<String, dynamic>> orders) {
    if (_isDisposed) return;
    final newIds = orders
        .map((order) => order['_id']?.toString())
        .whereType<String>()
        .toSet();
    final existingIds = _trackedOrders.keys.toSet();

    var didChange = false;

    for (final removedId in existingIds.difference(newIds)) {
      _removeOrder(removedId);
      didChange = true;
    }

    for (final id in newIds) {
      _trackedOrders.putIfAbsent(id, () => TrackedOrderState());
    }

    for (final order in orders) {
      final orderId = order['_id']?.toString();
      if (orderId == null) continue;
      final state = _trackedOrders[orderId];
      if (state == null) continue;

      if (_bootstrappingOrders.contains(orderId)) continue;

      if (!state.hasBootstrapped) {
        _bootstrappingOrders.add(orderId);
        state.isRouteLoading = true;
        didChange = true;
        unawaited(_bootstrapOrder(orderId, order));
      } else {
        final changed = _updateCachedCustomerLocation(orderId, order);
        didChange = didChange || changed;
      }
    }

    if (didChange) {
      _notifySafely();
    }
  }

  void _attachSocketListeners() {
    if (_driverLocationListener != null) {
      SocketService.removeListener(
        'driver-location-update',
        _driverLocationListener!,
      );
    }

    _driverLocationListener = (dynamic payload) {
      if (_isDisposed) return;
      final data = _normalizePayload(payload);
      if (data == null) return;

      final driverId = data['driverId']?.toString();
      final updatedLocation = _latLngFrom(data['location']);
      if (driverId == null || updatedLocation == null) return;

      var shouldNotify = false;
      for (final order in orderViewModel.activeOrders) {
        final orderId = order['_id']?.toString();
        if (orderId == null) continue;
        final orderDriverId = _extractId(order['driverId']);
        if (orderDriverId != driverId) continue;

        final state = _trackedOrders[orderId];
        if (state == null) continue;

        final current = state.driverLocation;
        if (current != null &&
            current.latitude == updatedLocation.latitude &&
            current.longitude == updatedLocation.longitude) {
          continue;
        }

        state.driverLocation = updatedLocation;
        shouldNotify = true;
        _scheduleRouteRefresh(orderId, order);
      }

      if (shouldNotify) {
        _notifySafely();
      }
    };

    SocketService.on('driver-location-update', _driverLocationListener!);
  }

  Future<void> _bootstrapOrder(
    String orderId,
    Map<String, dynamic> order,
  ) async {
    final state = _trackedOrders[orderId];
    if (state == null) {
      _bootstrappingOrders.remove(orderId);
      return;
    }

    LatLng? driverLocation = _latLngFrom(order['driverId']?['location']);
    if (driverLocation == null && order['driverId'] != null) {
      try {
        final response = await ApiService.getOrderById(orderId);
        final updatedOrder = response['order'] as Map<String, dynamic>?;
        if (updatedOrder != null) {
          driverLocation = _latLngFrom(updatedOrder['driverId']?['location']);
        }
      } catch (error) {
        debugPrint('Error bootstrapping order $orderId: $error');
      }
    }

    final customerLocation = _resolveCustomerLocation(order);

    if (_isDisposed) {
      _bootstrappingOrders.remove(orderId);
      return;
    }

    if (driverLocation != null) {
      state.driverLocation = driverLocation;
    }
    if (customerLocation != null) {
      state.customerLocation = customerLocation;
    }

    _notifySafely();

    await _updateRouteForOrder(
      orderId: orderId,
      order: order,
      driverOverride: driverLocation,
      customerOverride: customerLocation,
    );

    _bootstrappingOrders.remove(orderId);
  }

  bool _updateCachedCustomerLocation(
    String orderId,
    Map<String, dynamic> order,
  ) {
    final state = _trackedOrders[orderId];
    if (state == null) return false;

    final next = _resolveCustomerLocation(order);
    if (next == null) return false;

    final current = state.customerLocation;
    if (current != null &&
        current.latitude == next.latitude &&
        current.longitude == next.longitude) {
      return false;
    }

    state.customerLocation = next;
    return true;
  }

  Future<void> _updateRouteForOrder({
    required String orderId,
    required Map<String, dynamic> order,
    LatLng? driverOverride,
    LatLng? customerOverride,
  }) async {
    final state = _trackedOrders[orderId];
    if (state == null || _isDisposed) {
      return;
    }

    final driverLocation = driverOverride ??
        state.driverLocation ??
        _latLngFrom(order['driverId']?['location']) ??
        _latLngFrom(order['pickupLocation']);

    final customerLocation = customerOverride ??
        state.customerLocation ??
        _latLngFrom(order['dropoffLocation']);

    if (driverLocation == null || customerLocation == null) {
      state.isRouteLoading = false;
      if (driverLocation != null) {
        state.driverLocation = driverLocation;
      }
      if (customerLocation != null) {
        state.customerLocation = customerLocation;
      }
      state.routePoints = const [];
      state.distanceMeters = null;
      _notifySafely();
      return;
    }

    state.driverLocation = driverLocation;
    state.customerLocation = customerLocation;
    state.isRouteLoading = true;
    _notifySafely();

    try {
      final route = await RouteUtils.getRoute(
        startLat: driverLocation.latitude,
        startLng: driverLocation.longitude,
        endLat: customerLocation.latitude,
        endLng: customerLocation.longitude,
      );

      final distance = await RouteUtils.getRouteDistance(
        startLat: driverLocation.latitude,
        startLng: driverLocation.longitude,
        endLat: customerLocation.latitude,
        endLng: customerLocation.longitude,
      );

      if (_isDisposed) return;

      state.routePoints = List<LatLng>.unmodifiable(route);
      state.distanceMeters = distance;
      state.isRouteLoading = false;
      state.lastRouteRefresh = DateTime.now();

      final center = _calculateCenter(driverLocation, customerLocation);
      if (center != null) {
        // Use the state's setPendingCenter method which handles map readiness
        state.setPendingCenter(center);
      }

      _notifySafely();
    } catch (error) {
      debugPrint('Error calculating route for $orderId: $error');
      if (_isDisposed) return;
      state.isRouteLoading = false;
      _notifySafely();
    }
  }

  void _scheduleRouteRefresh(String orderId, Map<String, dynamic> order) {
    if (_isDisposed) return;
    final state = _trackedOrders[orderId];
    if (state == null) return;

    final now = DateTime.now();
    final lastRefresh = state.lastRouteRefresh;
    final isLoading = state.isRouteLoading;

    if (!isLoading &&
        (lastRefresh == null ||
            now.difference(lastRefresh) >= _routeRefreshThrottle)) {
      _routeRefreshTimers.remove(orderId)?.cancel();
      unawaited(_updateRouteForOrder(orderId: orderId, order: order));
      return;
    }

    final elapsed =
        lastRefresh == null ? Duration.zero : now.difference(lastRefresh);
    final delay = _routeRefreshThrottle - elapsed;
    final remaining = delay.isNegative ? Duration.zero : delay;

    _routeRefreshTimers.remove(orderId)?.cancel();
    _routeRefreshTimers[orderId] = Timer(remaining, () {
      _routeRefreshTimers.remove(orderId);
      if (_isDisposed) return;
      unawaited(_updateRouteForOrder(orderId: orderId, order: order));
    });
  }

  void _maybeUpdateUserLocation() {
    if (_isDisposed) return;
    final position = locationViewModel.currentPosition;
    if (position == null) return;

    final next = LatLng(position.latitude, position.longitude);
    if (_lastUserLocation != null &&
        _lastUserLocation!.latitude == next.latitude &&
        _lastUserLocation!.longitude == next.longitude) {
      return;
    }

    _lastUserLocation = next;

    var didChange = false;
    for (final order in orderViewModel.activeOrders) {
      final orderId = order['_id']?.toString();
      if (orderId == null) continue;
      final state = _trackedOrders[orderId];
      if (state == null) continue;

      final current = state.customerLocation;
      if (current != null &&
          current.latitude == next.latitude &&
          current.longitude == next.longitude) {
        continue;
      }

      state.customerLocation = next;
      didChange = true;
      _scheduleRouteRefresh(orderId, order);
    }

    if (didChange) {
      _notifySafely();
    }
  }

  void _removeOrder(String orderId) {
    _routeRefreshTimers.remove(orderId)?.cancel();
    _bootstrappingOrders.remove(orderId);
    _trackedOrders.remove(orderId);
  }

  void _notifySafely() {
    if (_isDisposed) return;
    notifyListeners();
  }

  Map<String, dynamic>? _normalizePayload(dynamic payload) {
    if (payload == null) return null;
    if (payload is Map<String, dynamic>) {
      return Map<String, dynamic>.from(payload);
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(
        payload.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }

  String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      final id = value['_id'] ?? value['id'];
      if (id != null) return id.toString();
    }
    return value.toString();
  }

  LatLng? _resolveCustomerLocation(Map<String, dynamic> order) {
    final position = locationViewModel.currentPosition;
    if (position != null) {
      return LatLng(position.latitude, position.longitude);
    }
    return _latLngFrom(order['dropoffLocation']);
  }

  LatLng? _calculateCenter(LatLng? first, LatLng? second) {
    if (first == null && second == null) return null;
    if (first == null) return second;
    if (second == null) return first;
    return LatLng(
      (first.latitude + second.latitude) / 2,
      (first.longitude + second.longitude) / 2,
    );
  }

  LatLng? _latLngFrom(dynamic data) {
    if (data is Map) {
      final rawLat = data['lat'] ?? data['latitude'];
      final rawLng = data['lng'] ?? data['longitude'];

      final lat =
          rawLat is num ? rawLat.toDouble() : double.tryParse('$rawLat');
      final lng =
          rawLng is num ? rawLng.toDouble() : double.tryParse('$rawLng');

      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }
}
