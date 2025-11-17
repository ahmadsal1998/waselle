import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../../view_models/location_view_model.dart';
import '../../view_models/map_style_view_model.dart';
import '../../view_models/order_view_model.dart';
import '../../services/route_service.dart';
import '../../utils/address_formatter.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String? orderId;

  const OrderDetailsScreen({super.key, this.orderId});

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
  int _currentOrderIndex = 0;
  List<Map<String, dynamic>> _activeOrders = [];
  bool _isDetailsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orderViewModel =
          Provider.of<OrderViewModel>(context, listen: false);
      
      // Load active orders
      await orderViewModel.fetchMyOrders();
      final activeOrders = orderViewModel.activeOrders;
      
      if (activeOrders.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _activeOrders = activeOrders;
        _currentOrderIndex = 0;
      });

      // If specific orderId provided, find its index
      if (widget.orderId != null) {
        final index = activeOrders.indexWhere((o) {
          final id = _getOrderId(o);
          return id == widget.orderId;
        });
        if (index != -1) {
          setState(() {
            _currentOrderIndex = index;
          });
        }
      }

      await _loadCurrentOrder();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String? _getOrderId(Map<String, dynamic> order) {
    final id = order['_id'];
    if (id is String) return id;
    if (id is Map<String, dynamic>) {
      return id['_id'] ?? id['\$oid'] ?? id['oid'];
    }
    return id?.toString();
  }

  Future<void> _loadCurrentOrder() async {
    if (_activeOrders.isEmpty || _currentOrderIndex >= _activeOrders.length) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final currentOrder = _activeOrders[_currentOrderIndex];
      final orderId = _getOrderId(currentOrder);
      
      if (orderId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final orderViewModel =
          Provider.of<OrderViewModel>(context, listen: false);
      final order = await orderViewModel.fetchOrderById(orderId);
      
      if (order != null) {
        setState(() {
          _order = order;
          _isLoading = false;
        });

        // Start location updates
        _startLocationUpdates();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _switchToOrder(int index) {
    if (index < 0 || index >= _activeOrders.length) return;
    
    setState(() {
      _currentOrderIndex = index;
      _isLoading = true;
      _routePoints = [];
      _driverLocation = null;
      _customerLocation = null;
      _userHasInteracted = false;
      _autoCenterEnabled = true;
    });
    
    _locationUpdateTimer?.cancel();
    _loadCurrentOrder();
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

    final locationViewModel =
        Provider.of<LocationViewModel>(context, listen: false);
    
    // Get driver location (current user location)
    if (locationViewModel.currentPosition != null) {
      _driverLocation = LatLng(
        locationViewModel.currentPosition!.latitude,
        locationViewModel.currentPosition!.longitude,
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
    final l10n = AppLocalizations.of(context)!;
    final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
    final orderId = _getOrderId(_order!);
    
    if (orderId == null) return;
    
    final success = await orderViewModel.updateOrderStatus(
      orderId: orderId,
      status: status,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.orderStatusUpdated(status))),
      );
      await _loadOrders();
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.orderDetails)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeOrders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.orderDetails)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                l10n.noActiveOrder,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.orderDetails)),
        body: Center(child: Text(l10n.orderNotFound)),
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

    final orderId = _getOrderId(_order!);
    final orderStatus = _order!['status']?.toString() ?? '';
    final orderPrice = _order!['price']?.toString() ?? '0';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderDetails),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: l10n.driverDashboard,
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onMapEvent: _onMapEvent,
              onPointerDown: (event, point) {
                if (!_userHasInteracted) {
                  setState(() {
                    _userHasInteracted = true;
                  });
                }
              },
            ),
            children: [
              Consumer<MapStyleViewModel>(
                builder: (context, mapStyleViewModel, _) {
                  final subdomains = mapStyleViewModel.getSubdomains();
                  return TileLayer(
                    urlTemplate: mapStyleViewModel.getUrlTemplate(),
                    userAgentPackageName: 'com.delivery.driverapp',
                    maxZoom: mapStyleViewModel.getMaxZoom().toDouble(),
                    subdomains: subdomains ?? const ['a', 'b', 'c'],
                    retinaMode: mapStyleViewModel.useRetinaTiles()
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
                    strokeWidth: 5.0,
                    color: theme.colorScheme.primary,
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
                            color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                          ),
                        ),
                        Icon(
                          Icons.delivery_dining,
                          color: theme.colorScheme.secondary,
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
                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        Icon(
                          Icons.person,
                          color: theme.colorScheme.primary,
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
                    child: Icon(
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
                    child: Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                ],
              ),
              Consumer<MapStyleViewModel>(
                builder: (context, mapStyleViewModel, _) {
                  final attribution = mapStyleViewModel.getAttribution();
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
          
          // Loading overlay
          if (_isLoadingRoute)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // Order details card overlay at top - compact and semi-transparent
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Compact order details card
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: _isDetailsExpanded 
                          ? (MediaQuery.of(context).size.height * 0.65)
                          : double.infinity,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          mainAxisSize: _isDetailsExpanded ? MainAxisSize.max : MainAxisSize.min,
                          children: [
                            // Compact header with navigation and expand button
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Order navigation (if multiple orders)
                                  if (_activeOrders.length > 1) ...[
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left, size: 20),
                                      onPressed: _currentOrderIndex > 0
                                          ? () => _switchToOrder(_currentOrderIndex - 1)
                                          : null,
                                      style: IconButton.styleFrom(
                                        backgroundColor: theme.colorScheme.surface.withOpacity(0.8),
                                        padding: const EdgeInsets.all(8),
                                        minimumSize: const Size(32, 32),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${l10n.order} ${_currentOrderIndex + 1}/${_activeOrders.length}',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right, size: 20),
                                      onPressed: _currentOrderIndex < _activeOrders.length - 1
                                          ? () => _switchToOrder(_currentOrderIndex + 1)
                                          : null,
                                      style: IconButton.styleFrom(
                                        backgroundColor: theme.colorScheme.surface.withOpacity(0.8),
                                        padding: const EdgeInsets.all(8),
                                        minimumSize: const Size(32, 32),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ] else ...[
                                    Expanded(
                                      child: Text(
                                        l10n.orderDetails,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  // Expand/Collapse button
                                  IconButton(
                                    icon: Icon(
                                      _isDetailsExpanded 
                                          ? Icons.expand_less 
                                          : Icons.expand_more,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isDetailsExpanded = !_isDetailsExpanded;
                                      });
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: theme.colorScheme.surface.withOpacity(0.8),
                                      padding: const EdgeInsets.all(8),
                                      minimumSize: const Size(32, 32),
                                    ),
                                    tooltip: _isDetailsExpanded 
                                        ? 'Collapse details' 
                                        : 'Expand details',
                                  ),
                                ],
                              ),
                            ),
                            // Compact or expanded content
                            if (_isDetailsExpanded)
                              Expanded(
                                child: _buildExpandedDetails(theme, l10n, pickup, dropoff, orderStatus, orderPrice),
                              )
                            else
                              _buildCompactDetails(theme, l10n, orderStatus, orderPrice),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Center on driver button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: "center-on-driver",
              onPressed: _centerOnDriver,
              backgroundColor: theme.colorScheme.secondary,
              child: Icon(Icons.my_location, color: theme.colorScheme.onSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildCompactDetails(ThemeData theme, AppLocalizations l10n, String orderStatus, String orderPrice) {
    // Get customer name and phone from populated customer data or order fields
    final customerName = AddressFormatter.getCustomerName(_order!);
    final customerPhone = AddressFormatter.getCustomerPhone(_order!);
    final address = AddressFormatter.formatAddress(_order!);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: orderStatus == 'on_the_way'
                      ? theme.colorScheme.tertiary.withOpacity(0.15)
                      : theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  orderStatus.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: orderStatus == 'on_the_way'
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${l10n.nis(orderPrice)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Customer name and phone (compact)
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  customerName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.phone, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text(
                customerPhone,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Address (compact)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Action button
          const SizedBox(height: 12),
          if (orderStatus == 'accepted')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus('on_the_way'),
                icon: const Icon(Icons.directions_car, size: 18),
                label: Text(l10n.startDelivery),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (orderStatus == 'on_the_way')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus('delivered'),
                icon: const Icon(Icons.check_circle, size: 18),
                label: Text(l10n.markAsDelivered),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: theme.colorScheme.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(ThemeData theme, AppLocalizations l10n, Map<String, dynamic> pickup, Map<String, dynamic> dropoff, String orderStatus, String orderPrice) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
            // Status and Price Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.status,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: orderStatus == 'on_the_way'
                              ? theme.colorScheme.tertiary.withOpacity(0.15)
                              : theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          orderStatus.toUpperCase(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: orderStatus == 'on_the_way'
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.price,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.nis(orderPrice)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Customer Information
            const SizedBox(height: 16),
            _buildInfoSection(
              theme: theme,
              icon: Icons.person,
              title: l10n.sender,
              children: [
                _buildInfoRow(
                  theme: theme,
                  icon: Icons.person_outline,
                  label: l10n.name,
                  value: AddressFormatter.getCustomerName(_order!),
                ),
                _buildInfoRow(
                  theme: theme,
                  icon: Icons.phone,
                  label: l10n.phone,
                  value: AddressFormatter.getCustomerPhone(_order!),
                ),
              ],
            ),
            
            // Address Information (new format: City-Village-StreetDetails)
            const SizedBox(height: 12),
            _buildInfoSection(
              theme: theme,
              icon: Icons.location_on,
              title: l10n.address,
              children: [
                _buildInfoRow(
                  theme: theme,
                  icon: Icons.location_on_outlined,
                  label: l10n.address,
                  value: AddressFormatter.formatAddress(_order!),
                ),
              ],
            ),
            
            // Pickup Location
            const SizedBox(height: 12),
            _buildInfoSection(
              theme: theme,
              icon: Icons.location_on,
              title: 'Pickup Location',
              children: [
                _buildInfoRow(
                  theme: theme,
                  icon: Icons.location_on_outlined,
                  label: l10n.address,
                  value: pickup['address']?.toString() ?? 
                         _formatCoordinates(pickup['lat'], pickup['lng']),
                ),
              ],
            ),
            
            // Delivery Location
            const SizedBox(height: 12),
            _buildInfoSection(
              theme: theme,
              icon: Icons.flag,
              title: 'Delivery Location',
              children: [
                _buildInfoRow(
                  theme: theme,
                  icon: Icons.location_on_outlined,
                  label: l10n.address,
                  value: dropoff['address']?.toString() ?? 
                         _formatCoordinates(dropoff['lat'], dropoff['lng']),
                ),
              ],
            ),
            
            // Vehicle Type
            const SizedBox(height: 12),
            _buildInfoRow(
              theme: theme,
              icon: Icons.directions_car,
              label: l10n.vehicle,
              value: _order!['vehicleType']?.toString().toUpperCase() ?? l10n.nA,
            ),
            
            // Delivery Notes
            if (_order!['deliveryNotes'] != null && 
                _order!['deliveryNotes'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoSection(
                theme: theme,
                icon: Icons.note,
                title: l10n.notes,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 4),
                    child: Text(
                      _order!['deliveryNotes'].toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            
            // Distance
            if (_driverLocation != null && _customerLocation != null) ...[
              const SizedBox(height: 12),
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
                    return _buildInfoRow(
                      theme: theme,
                      icon: Icons.straighten,
                      label: l10n.distance,
                      value: '${distanceKm.toStringAsFixed(2)} km',
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
            
            // Action Buttons
            const SizedBox(height: 16),
            if (orderStatus == 'accepted')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus('on_the_way'),
                  icon: const Icon(Icons.directions_car),
                  label: Text(l10n.startDelivery),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            if (orderStatus == 'on_the_way')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus('delivered'),
                  icon: const Icon(Icons.check_circle),
                  label: Text(l10n.markAsDelivered),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.secondary,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  String _formatCoordinates(dynamic lat, dynamic lng) {
    try {
      final latValue = lat is num ? lat.toDouble() : (lat != null ? double.tryParse(lat.toString()) : null);
      final lngValue = lng is num ? lng.toDouble() : (lng != null ? double.tryParse(lng.toString()) : null);
      if (latValue != null && lngValue != null) {
        return '${latValue.toStringAsFixed(6)}, ${lngValue.toStringAsFixed(6)}';
      }
    } catch (e) {
      // Ignore errors
    }
    return 'N/A';
  }

  Widget _buildInfoRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
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