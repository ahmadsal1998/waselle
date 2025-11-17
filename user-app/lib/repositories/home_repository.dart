import 'package:geolocator/geolocator.dart';

import '../services/socket_service.dart';
import '../view_models/driver_view_model.dart';
import '../view_models/location_view_model.dart';
import '../view_models/order_view_model.dart';
import '../view_models/auth_view_model.dart';

class HomeRepository {
  final LocationViewModel locationViewModel;
  final OrderViewModel orderViewModel;
  final DriverViewModel driverViewModel;
  final AuthViewModel authViewModel;

  HomeRepository({
    required this.locationViewModel,
    required this.orderViewModel,
    required this.driverViewModel,
    required this.authViewModel,
  });

  Future<void> initializeHome() async {
    // Get location (doesn't require auth)
    await locationViewModel.getCurrentLocation();
    locationViewModel.startLocationUpdates();

    // Only fetch orders and drivers if authenticated
    if (authViewModel.isAuthenticated) {
      await Future.wait([
        orderViewModel.fetchOrders(),
        driverViewModel.fetchDrivers(),
      ]);

      await SocketService.initialize();
      driverViewModel.attachSocketListeners();
    }
  }

  Future<void> refreshLocation() => locationViewModel.getCurrentLocation();

  void stopLocationUpdates() {
    locationViewModel.stopLocationUpdates();
  }

  Future<void> refreshDrivers() async {
    if (authViewModel.isAuthenticated) {
      await driverViewModel.fetchDrivers();
    }
  }

  Future<void> refreshOrders() async {
    if (authViewModel.isAuthenticated) {
      await orderViewModel.fetchOrders();
    }
  }

  bool get hasActiveOrder => orderViewModel.activeOrders.isNotEmpty;

  List<Map<String, dynamic>> get driverData => driverViewModel.drivers;

  bool get isDriverLoading => driverViewModel.isLoading;

  bool get isLocationLoading => locationViewModel.isLoading;

  String? get locationErrorMessage => locationViewModel.errorMessage;

  Position? get currentPosition => locationViewModel.currentPosition;

  String? get currentAddress => locationViewModel.currentAddress;
}
