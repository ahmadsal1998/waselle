import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/map_style_provider.dart';
import '../../services/api_service.dart';
import '../../services/route_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  LatLng? _driverLocation;
  LatLng? _customerLocation;
  Timer? _locationUpdateTimer;
  bool _isLoadingRoute = false;
  bool _userHasInteracted = false; // Track if user has zoomed/panned
  bool _autoCenterEnabled = true; // Auto-center enabled by default
  bool _isProgrammaticMove = false; // Track if move is programmatic

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final response = await ApiService.getOrderById(widget.orderId);
      if (response['order'] != null) {
        setState(() {
          _order = response['order'];
          _isLoading = false;
        });
        
        // Start location updates
        _startLocationUpdates();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startLocationUpdates() {
    // Update route every 5 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _updateRoute();
      }
    });
    
    // Initial update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRoute();
    });
  }

  Future<void> _updateRoute() async {
    if (_order == null) return;

    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    // Get driver location (current user location)
    if (locationProvider.currentPosition != null) {
      _driverLocation = LatLng(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      );
    }

    // Get customer location from order (dropoff location)
    final dropoff = _order!['dropoffLocation'];
    _customerLocation = LatLng(
      dropoff['lat'].toDouble(),
      dropoff['lng'].toDouble(),
    );

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

        // Only center map if auto-center is enabled and user hasn't interacted
        if (_routePoints.isNotEmpty && _autoCenterEnabled && !_userHasInteracted) {
          final center = LatLng(
            (_driverLocation!.latitude + _customerLocation!.latitude) / 2,
            (_driverLocation!.longitude + _customerLocation!.longitude) / 2,
          );
          _isProgrammaticMove = true;
          _mapController.move(center, _mapController.camera.zoom);
          // Reset flag after a short delay
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _isProgrammaticMove = false;
            }
          });
        }
        // If user has interacted, just update the marker position without recentering
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

  Future<void> _updateStatus(String status) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final success = await orderProvider.updateOrderStatus(
      orderId: widget.orderId,
      status: status,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $status')),
      );
      await _loadOrder();
    }
  }

  void _centerOnDriver() {
    if (_driverLocation != null) {
      setState(() {
        _autoCenterEnabled = true;
        _userHasInteracted = false;
      });
      _isProgrammaticMove = true;
      _mapController.move(_driverLocation!, _mapController.camera.zoom);
      // Reset flag after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _isProgrammaticMove = false;
        }
      });
    }
  }

  void _onMapEvent(MapEvent event) {
    // Only detect user interaction, not programmatic moves
    if (_isProgrammaticMove) return;
    
    // Detect user interaction events
    // These events indicate user interaction, not programmatic moves
    if (event is MapEventScrollWheelZoom || 
        event is MapEventFlingAnimation ||
        event is MapEventTap) {
      if (!_userHasInteracted) {
        setState(() {
          _userHasInteracted = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return const Scaffold(
        body: Center(child: Text('Order not found')),
      );
    }

    final pickup = _order!['pickupLocation'];
    final dropoff = _order!['dropoffLocation'];
    
    // Use driver location if available, otherwise use pickup
    final driverLoc = _driverLocation ?? 
        LatLng(pickup['lat'].toDouble(), pickup['lng'].toDouble());
    
    // Use customer location (dropoff)
    final customerLoc = _customerLocation ?? 
        LatLng(dropoff['lat'].toDouble(), dropoff['lng'].toDouble());

    final center = LatLng(
      (driverLoc.latitude + customerLoc.latitude) / 2,
      (driverLoc.longitude + customerLoc.longitude) / 2,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Column(
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
                    onMapEvent: _onMapEvent,
                    onPointerDown: (event, point) {
                      // User started interacting with map
                      if (!_userHasInteracted) {
                        setState(() {
                          _userHasInteracted = true;
                        });
                      }
                    },
                  ),
                  children: [
                    Consumer<MapStyleProvider>(
                      builder: (context, mapStyleProvider, _) {
                        final subdomains = mapStyleProvider.getSubdomains();
                        return TileLayer(
                          urlTemplate: mapStyleProvider.getUrlTemplate(),
                          userAgentPackageName: 'com.delivery.driverapp',
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
                        // Driver marker (you)
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
                        // Customer marker
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
                          point: LatLng(pickup['lat'].toDouble(), pickup['lng'].toDouble()),
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
                          point: LatLng(dropoff['lat'].toDouble(), dropoff['lng'].toDouble()),
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
                // Center on Me button
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    heroTag: "center-on-driver",
                    onPressed: _centerOnDriver,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.my_location, color: Colors.white),
                    tooltip: 'Center on Driver',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Status: ${_order!['status']}'),
                const SizedBox(height: 8),
                Text('Price: \$${_order!['price']}'),
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
                            'Distance to customer: ${distanceKm.toStringAsFixed(2)} km',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                const SizedBox(height: 16),
                if (_order!['status'] == 'accepted')
                  ElevatedButton(
                    onPressed: () => _updateStatus('on_the_way'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'Start Delivery',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (_order!['status'] == 'on_the_way')
                  ElevatedButton(
                    onPressed: () => _updateStatus('delivered'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Mark as Delivered',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}