import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/location_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/map_style_provider.dart';
import '../../providers/driver_provider.dart';
import '../../services/socket_service.dart';
import 'send_request_screen.dart';
import 'receive_request_screen.dart';
import 'order_tracking_screen.dart';
import 'profile_screen.dart';
import 'order_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _tabTitles = [
    'Delivery App',
    'Profile',
    'Track Order',
    'Order History',
  ];

  final MapController _mapController = MapController();
  LatLng? _lastLocation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    final locationProvider = context.read<LocationProvider>();
    final orderProvider = context.read<OrderProvider>();
    final driverProvider = context.read<DriverProvider>();

    await locationProvider.getCurrentLocation();
    if (!mounted) return;

    locationProvider.startLocationUpdates();
    if (!mounted) return;

    await Future.wait([
      orderProvider.fetchOrders(),
      driverProvider.fetchDrivers(),
    ]);
    if (!mounted) return;

    await SocketService.initialize();
    if (!mounted) return;

    driverProvider.attachSocketListeners();
  }

  @override
  void dispose() {
    // Stop location updates before disposing
    try {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      locationProvider.stopLocationUpdates();
    } catch (e) {
      // Ignore errors if context is no longer available
    }
    super.dispose();
  }

  void _centerOnUserLocation(LocationProvider locationProvider) {
    if (locationProvider.currentPosition != null) {
      final pos = locationProvider.currentPosition!;
      final loc = LatLng(pos.latitude, pos.longitude);
      _mapController.move(loc, 15.0);
      locationProvider.getCurrentLocation();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_tabTitles[_currentIndex]),
    );
  }

  Widget _buildMapView() {
    return Consumer2<LocationProvider, DriverProvider>(
      builder: (_, locationProvider, driverProvider, __) {
        return _buildMapContent(locationProvider, driverProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMapView(),
          const ProfileScreen(showAppBar: false),
          const OrderTrackingScreen(showAppBar: false),
          const OrderHistoryScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Consumer<OrderProvider>(
              builder: (context, orderProvider, _) {
                final hasActiveOrder = orderProvider.activeOrder != null;
                final isSelected = _currentIndex == 2;
                final iconColor = isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).iconTheme.color?.withOpacity(0.7) ??
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.track_changes, color: iconColor),
                    if (hasActiveOrder)
                      Positioned(
                        right: -6,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Track',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent(
    LocationProvider locationProvider,
    DriverProvider driverProvider,
  ) {
    if (_isInitialLoading(locationProvider)) {
      return _buildLoadingState();
    }

    if (_hasLocationError(locationProvider)) {
      return _buildErrorState(locationProvider);
    }

    if (locationProvider.currentPosition == null) {
      return _buildNoLocationState(locationProvider);
    }

    final currentLocation = LatLng(
      locationProvider.currentPosition!.latitude,
      locationProvider.currentPosition!.longitude,
    );

    _syncMapCenter(currentLocation);

    final driverMarkers = _buildDriverMarkers(driverProvider.drivers);

    return Stack(
      children: [
        _buildMap(currentLocation, driverMarkers),
        _buildLocationOverlay(locationProvider, currentLocation),
        _buildActionButtons(),
      ],
    );
  }

  bool _isInitialLoading(LocationProvider locationProvider) {
    return locationProvider.isLoading &&
        locationProvider.currentPosition == null;
  }

  bool _hasLocationError(LocationProvider locationProvider) {
    return locationProvider.errorMessage != null &&
        locationProvider.currentPosition == null;
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Getting your location...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(LocationProvider locationProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              locationProvider.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => locationProvider.getCurrentLocation(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLocationState(LocationProvider locationProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Location not available'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => locationProvider.getCurrentLocation(),
            icon: const Icon(Icons.refresh),
            label: const Text('Get Location'),
          ),
        ],
      ),
    );
  }

  void _syncMapCenter(LatLng currentLocation) {
    if (_lastLocation == null ||
        _lastLocation!.latitude != currentLocation.latitude ||
        _lastLocation!.longitude != currentLocation.longitude) {
      _lastLocation = currentLocation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(
            currentLocation,
            _mapController.camera.zoom,
          );
        }
      });
    }
  }

  List<Marker> _buildDriverMarkers(List<dynamic> drivers) {
    return drivers
        .whereType<Map<String, dynamic>>()
        .map(_createDriverMarker)
        .whereType<Marker>()
        .toList(growable: false);
  }

  Widget _buildMap(LatLng currentLocation, List<Marker> driverMarkers) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: currentLocation,
        initialZoom: 15.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        onTap: (_, __) {},
      ),
      children: [
        _buildTileLayer(),
        MarkerLayer(
          markers: [
            _buildUserMarker(currentLocation),
            ...driverMarkers,
          ],
        ),
        _buildAttribution(),
      ],
    );
  }

  Widget _buildTileLayer() {
    return Consumer<MapStyleProvider>(
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
    );
  }

  Marker _buildUserMarker(LatLng currentLocation) {
    return Marker(
      point: currentLocation,
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.4),
            ),
          ),
          const Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildAttribution() {
    return Consumer<MapStyleProvider>(
      builder: (context, mapStyleProvider, _) {
        final attribution = mapStyleProvider.getAttribution();
        if (attribution == null || attribution.isEmpty) {
          return const SizedBox.shrink();
        }
        return RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          attributions: [
            TextSourceAttribution(attribution),
          ],
        );
      },
    );
  }

  Widget _buildLocationOverlay(
    LocationProvider locationProvider,
    LatLng currentLocation,
  ) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.place,
              color: Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locationProvider.currentAddress ??
                    '${currentLocation.latitude.toStringAsFixed(6)}, ${currentLocation.longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Locate Me',
              onPressed: () => _centerOnUserLocation(locationProvider),
              icon: const Icon(Icons.my_location),
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SendRequestScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.send),
              label: const Text('Send Request'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReceiveRequestScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.call_received),
              label: const Text('Receive Request'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker? _createDriverMarker(Map<String, dynamic> driver) {
    final location = driver['location'];
    if (location is! Map<String, dynamic>) return null;

    final lat = _parseToDouble(location['lat']);
    final lng = _parseToDouble(location['lng']);
    if (lat == null || lng == null) return null;

    final isAvailable = driver['isAvailable'] == true;
    final color = isAvailable ? Colors.green : Colors.orange;
    final name = driver['name']?.toString();

    return Marker(
      point: LatLng(lat, lng),
      width: 80,
      height: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (name != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 4),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(
              Icons.delivery_dining,
              color: color,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}