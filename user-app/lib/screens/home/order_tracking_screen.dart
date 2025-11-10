import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/map_style_provider.dart';
import '../../services/route_service.dart';
import '../../services/api_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  LatLng? _driverLocation;
  LatLng? _customerLocation;
  Timer? _locationUpdateTimer;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider =
          Provider.of<OrderProvider>(context, listen: false);
      if (orderProvider.activeOrder == null) {
        orderProvider.fetchOrders();
      }
    });
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    // Update driver location every 5 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _updateDriverLocation();
        _updateRoute();
      }
    });
    
    // Initial update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDriverLocation();
      _updateRoute();
    });
  }

  Future<void> _updateDriverLocation() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final order = orderProvider.activeOrder;
    
    if (order == null || order['driverId'] == null) return;

    try {
      // Fetch driver location from API
      final response = await ApiService.getOrderById(order['_id']);
      if (response['order'] != null) {
        final updatedOrder = response['order'];
        final driver = updatedOrder['driverId'];
        
        if (driver != null && driver['location'] != null) {
          setState(() {
            _driverLocation = LatLng(
              driver['location']['lat'].toDouble(),
              driver['location']['lng'].toDouble(),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching driver location: $e');
    }
  }

  Future<void> _updateRoute() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final order = orderProvider.activeOrder;
    
    if (order == null) return;

    // Get customer location (current user location)
    if (locationProvider.currentPosition != null) {
      _customerLocation = LatLng(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      );
    }

    // Get driver location
    if (_driverLocation == null) {
      await _updateDriverLocation();
    }

    if (_driverLocation == null || _customerLocation == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final route = await RouteService.getRoute(
        startLat: _driverLocation!.latitude,
        startLng: _driverLocation!.longitude,
        endLat: _customerLocation!.latitude,
        endLng: _customerLocation!.longitude,
      );

      if (mounted) {
        setState(() {
          _routePoints = route;
          _isLoadingRoute = false;
        });

        // Center map on route
        if (_routePoints.isNotEmpty) {
          final center = LatLng(
            (_driverLocation!.latitude + _customerLocation!.latitude) / 2,
            (_driverLocation!.longitude + _customerLocation!.longitude) / 2,
          );
          _mapController.move(center, 13.0);
        }
      }
    } catch (e) {
      debugPrint('Error calculating route: $e');
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Consumer2<OrderProvider, LocationProvider>(
      builder: (context, orderProvider, locationProvider, _) {
        final order = orderProvider.activeOrder;

        if (order == null) {
          return const Center(child: Text('No active order'));
        }

        final pickup = order['pickupLocation'];
        final dropoff = order['dropoffLocation'];

        // Use customer location if available, otherwise use dropoff
        final customerLoc = _customerLocation ??
            LatLng(dropoff['lat'].toDouble(), dropoff['lng'].toDouble());

        // Use driver location if available, otherwise use pickup
        final driverLoc = _driverLocation ??
            LatLng(pickup['lat'].toDouble(), pickup['lng'].toDouble());

        final center = LatLng(
          (driverLoc.latitude + customerLoc.latitude) / 2,
          (driverLoc.longitude + customerLoc.longitude) / 2,
        );

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 13.0,
                      minZoom: 5.0,
                      maxZoom: 18.0,
                    ),
                    children: [
                      Consumer<MapStyleProvider>(
                        builder: (context, mapStyleProvider, _) {
                          final subdomains = mapStyleProvider.getSubdomains();
                          return TileLayer(
                            urlTemplate: mapStyleProvider.getUrlTemplate(),
                            userAgentPackageName: 'com.delivery.userapp',
                            maxZoom: mapStyleProvider.getMaxZoom().toDouble(),
                            subdomains: subdomains ?? const ['a', 'b', 'c'],
                            retinaMode: mapStyleProvider.useRetinaTiles()
                                ? RetinaMode.isHighDensity(context)
                                : false,
                          );
                        },
                      ),
                      // Route polyline
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 4.0,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          // Driver marker
                          Marker(
                            point: driverLoc,
                            width: 50,
                            height: 50,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green.withOpacity(0.2),
                                  ),
                                ),
                                const Icon(
                                  Icons.delivery_dining,
                                  color: Colors.green,
                                  size: 35,
                                ),
                              ],
                            ),
                          ),
                          // Customer marker (you)
                          Marker(
                            point: customerLoc,
                            width: 50,
                            height: 50,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.withOpacity(0.2),
                                  ),
                                ),
                                const Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                  size: 35,
                                ),
                              ],
                            ),
                          ),
                          // Pickup marker
                          Marker(
                            point: LatLng(pickup['lat'].toDouble(),
                                pickup['lng'].toDouble()),
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.orange,
                              size: 30,
                            ),
                          ),
                          // Dropoff marker
                          Marker(
                            point: LatLng(dropoff['lat'].toDouble(),
                                dropoff['lng'].toDouble()),
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      Consumer<MapStyleProvider>(
                        builder: (context, mapStyleProvider, _) {
                          final attribution = mapStyleProvider.getAttribution();
                          if (attribution != null && attribution.isNotEmpty) {
                            return RichAttributionWidget(
                              alignment: AttributionAlignment.bottomRight,
                              attributions: [
                                TextSourceAttribution(attribution),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  if (_isLoadingRoute)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${order['status']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (order['driverId'] != null)
                    Text('Driver: ${order['driverId']['name'] ?? 'Unknown'}'),
                  const SizedBox(height: 8),
                  Text('Price: \$${order['price']}'),
                  if (_driverLocation != null && _customerLocation != null)
                    FutureBuilder<double?>(
                      future: RouteService.getRouteDistance(
                        startLat: _driverLocation!.latitude,
                        startLng: _driverLocation!.longitude,
                        endLat: _customerLocation!.latitude,
                        endLng: _customerLocation!.longitude,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final distanceKm = snapshot.data! / 1000;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Distance: ${distanceKm.toStringAsFixed(2)} km',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Order')),
        body: body,
      );
    }
    return body;
  }
}