import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';

import '../../view_models/location_view_model.dart';
import '../../view_models/map_style_view_model.dart';
import '../../view_models/order_view_model.dart';
import '../../view_models/order_tracking_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../services/zego_call_service.dart';
import 'order_map_view_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OrderTrackingViewModel>(
      create: (context) => OrderTrackingViewModel(
        orderViewModel: context.read<OrderViewModel>(),
        locationViewModel: context.read<LocationViewModel>(),
      )..initialize(),
      child: _OrderTrackingView(showAppBar: showAppBar),
    );
  }
}

class _OrderTrackingView extends StatelessWidget {
  const _OrderTrackingView({required this.showAppBar});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final body = Consumer2<OrderTrackingViewModel, MapStyleViewModel>(
      builder: (context, trackingViewModel, mapStyleProvider, _) {
        if (!trackingViewModel.isInitialized &&
            trackingViewModel.activeOrders.isEmpty) {
          return const _LoadingState();
        }

        final orders = trackingViewModel.activeOrders;

        if (orders.isEmpty) {
          return const _EmptyState();
        }

        return RefreshIndicator(
          onRefresh: trackingViewModel.refreshOrders,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderId = order['_id']?.toString();
              if (orderId == null) {
                return const SizedBox.shrink();
              }

              final state = trackingViewModel.stateFor(orderId);
              if (state == null) {
                return const SizedBox.shrink();
              }

              final pickup =
                  trackingViewModel.toLatLng(order['pickupLocation']);
              final dropoff =
                  trackingViewModel.toLatLng(order['dropoffLocation']);
              final center = _calculateCenter(
                    state.driverLocation ?? pickup,
                    state.customerLocation ?? dropoff,
                  ) ??
                  pickup ??
                  dropoff ??
                  _kDefaultMapCenter;

              return _TrackedOrderCard(
                order: order,
                state: state,
                mapStyleProvider: mapStyleProvider,
                center: center,
                pickup: pickup,
                dropoff: dropoff,
              );
            },
          ),
        );
      },
    );

    final l10n = AppLocalizations.of(context)!;
    if (showAppBar) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.trackOrders)),
        body: body,
      );
    }
    return body;
  }
}

class _TrackedOrderCard extends StatefulWidget {
  const _TrackedOrderCard({
    required this.order,
    required this.state,
    required this.mapStyleProvider,
    required this.center,
    this.pickup,
    this.dropoff,
  });

  final Map<String, dynamic> order;
  final TrackedOrderState state;
  final MapStyleViewModel mapStyleProvider;
  final LatLng center;
  final LatLng? pickup;
  final LatLng? dropoff;

  @override
  State<_TrackedOrderCard> createState() => _TrackedOrderCardState();
}

class _TrackedOrderCardState extends State<_TrackedOrderCard> {
  bool _isOrderProgressVisible = false;

  @override
  Widget build(BuildContext context) {
    final orderId = widget.order['_id']?.toString();
    if (orderId == null) {
      return const SizedBox.shrink();
    }

    final routePoints = widget.state.routePoints;
    final isLoadingRoute = widget.state.isRouteLoading;
    final distanceMeters = widget.state.distanceMeters;
    final formattedDate = _formatDate(widget.order['createdAt']);
    final status = widget.order['status']?.toString().toLowerCase() ?? 'unknown';

    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.5),
                  colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ${_readableOrderId(widget.order['_id']?.toString() ?? '')}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                      ),
                      if (formattedDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status, colorScheme).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _getStatusColor(status, colorScheme),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // Map Section
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrderMapViewScreen(
                    order: widget.order,
                    state: widget.state,
                  ),
                ),
              );
            },
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              child: Stack(
                children: [
                  ClipRect(
                    child: FlutterMap(
                    mapController: widget.state.mapController,
                    options: MapOptions(
                      initialCenter: widget.center,
                      initialZoom: 13.0,
                      minZoom: 5.0,
                      maxZoom: 18.0,
                      onMapReady: () {
                        widget.state.markMapReady();
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: widget.mapStyleProvider.getUrlTemplate(),
                        userAgentPackageName: 'com.delivery.userapp',
                        maxZoom: widget.mapStyleProvider.getMaxZoom().toDouble(),
                        subdomains: widget.mapStyleProvider.getSubdomains() ??
                            const ['a', 'b', 'c'],
                        retinaMode: widget.mapStyleProvider.useRetinaTiles()
                            ? RetinaMode.isHighDensity(context)
                            : false,
                      ),
                      if (routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              strokeWidth: 5.0,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (widget.state.driverLocation != null)
                            _buildMarker(
                              point: widget.state.driverLocation!,
                              color: Colors.green,
                              icon: Icons.delivery_dining_rounded,
                            ),
                          if (widget.state.customerLocation != null)
                            _buildMarker(
                              point: widget.state.customerLocation!,
                              color: Colors.blue,
                              icon: Icons.person_pin_circle_rounded,
                            ),
                          if (widget.pickup != null)
                            _buildMarker(
                              point: widget.pickup!,
                              color: Colors.orange,
                              icon: Icons.store_rounded,
                              size: 32,
                            ),
                          if (widget.dropoff != null)
                            _buildMarker(
                              point: widget.dropoff!,
                              color: Colors.red,
                              icon: Icons.location_on_rounded,
                              size: 32,
                            ),
                        ],
                      ),
                      if (widget.mapStyleProvider.getAttribution()?.isNotEmpty ??
                          false)
                        RichAttributionWidget(
                          alignment: AttributionAlignment.bottomRight,
                          attributions: [
                            TextSourceAttribution(
                              widget.mapStyleProvider.getAttribution()!,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (isLoadingRoute)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                // Map Info Overlay
                if (distanceMeters != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(distanceMeters / 1000).toStringAsFixed(1)} km',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tap indicator overlay
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_full_rounded,
                            size: 14,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.tapToOpenMap,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Order Stages Timeline Toggle Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.orderProgress,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    setState(() {
                      _isOrderProgressVisible = !_isOrderProgressVisible;
                    });
                  },
                  icon: Icon(
                    _isOrderProgressVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _isOrderProgressVisible
                        ? l10n.hideOrderProgress
                        : l10n.showOrderProgress,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Order Stages Timeline (Collapsible)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isOrderProgressVisible
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: _OrderStageTimeline(
                      currentStatus: status,
                      order: widget.order,
                      state: widget.state,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Driver Info Section
          if (widget.order['driverId'] != null)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  _InfoSection(
                    title: 'Driver Information',
                    rows: [
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Name',
                        value: widget.order['driverId']['name'],
                      ),
                      _InfoRow(
                        icon: Icons.phone_android_rounded,
                        label: 'Phone',
                        value: _formatPhone(widget.order['driverId']['phoneNumber']),
                      ),
                      _InfoRow(
                        icon: Icons.directions_car_filled_rounded,
                        label: 'Vehicle',
                        value: widget.order['driverId']['vehicleType'] ??
                            widget.order['vehicleType'],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Call Button
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, _) {
                      final orderId = widget.order['_id']?.toString();
                      final user = authViewModel.user;
                      if (orderId == null || user == null) {
                        return const SizedBox.shrink();
                      }
                      
                      // Backend returns 'id' field, not '_id' - handle both for compatibility
                      final userId = (user['id'] ?? user['_id'] ?? '').toString();
                      final userName = user['name']?.toString() ?? 'User';
                      
                      final driverId = widget.order['driverId']?['_id']?.toString();
                      
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            ZegoCallService.startCall(
                              context: context,
                              orderId: orderId,
                              userId: userId,
                              userName: userName,
                              driverId: driverId, // Driver is the receiver
                              customerId: null, // User is the caller, so customerId should be null
                            );
                          },
                          icon: const Icon(Icons.phone_rounded),
                          label: const Text('Call Driver'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'on_the_way':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return colorScheme.primary;
    }
  }
}

class _OrderStageTimeline extends StatelessWidget {
  const _OrderStageTimeline({
    required this.currentStatus,
    required this.order,
    required this.state,
  });

  final String currentStatus;
  final Map<String, dynamic> order;
  final TrackedOrderState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    
    final stages = [
      _OrderStage(
        id: 'pending',
        title: l10n.orderPlaced,
        description: l10n.orderPlacedDescription,
        icon: Icons.shopping_cart_outlined,
        color: Colors.orange,
      ),
      _OrderStage(
        id: 'accepted',
        title: l10n.orderAccepted,
        description: l10n.orderAcceptedDescription,
        icon: Icons.check_circle_outline,
        color: Colors.blue,
      ),
      _OrderStage(
        id: 'on_the_way',
        title: l10n.onTheWay,
        description: l10n.onTheWayDescription,
        icon: Icons.directions_car_outlined,
        color: Colors.purple,
      ),
      _OrderStage(
        id: 'delivered',
        title: l10n.delivered,
        description: l10n.deliveredDescription,
        icon: Icons.check_circle,
        color: Colors.green,
      ),
    ];

    // Handle cancelled status separately
    final isCancelled = currentStatus.toLowerCase() == 'cancelled';
    
    int currentIndex = 0;
    if (!isCancelled) {
      for (int i = 0; i < stages.length; i++) {
        if (stages[i].id == currentStatus.toLowerCase()) {
          currentIndex = i;
          break;
        }
      }
    } else {
      // For cancelled orders, show all stages as incomplete
      currentIndex = -1;
    }

    return Column(
      children: stages.asMap().entries.map((entry) {
        final index = entry.key;
        final stage = entry.value;
        final isCompleted = !isCancelled && index < currentIndex;
        final isCurrent = !isCancelled && index == currentIndex;
        final isPending = isCancelled || index > currentIndex;

        return InkWell(
          onTap: () => _showStageDetails(context, stage, order, state),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline indicator
                Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isCurrent
                            ? stage.color
                            : colorScheme.surfaceVariant,
                        border: isPending
                            ? Border.all(
                                color: colorScheme.outlineVariant,
                                width: 2,
                              )
                            : null,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: stage.color.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check
                            : isCurrent
                                ? stage.icon
                                : stage.icon,
                        color: isCompleted || isCurrent
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    if (index < stages.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? stage.color
                              : colorScheme.outlineVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Stage content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              stage.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: isCurrent || isCompleted
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isCurrent || isCompleted
                                        ? stage.color
                                        : colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: stage.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.current,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: stage.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stage.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showStageDetails(
    BuildContext context,
    _OrderStage stage,
    Map<String, dynamic> order,
    TrackedOrderState state,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StageDetailSheet(
        stage: stage,
        order: order,
        state: state,
      ),
    );
  }
}

class _OrderStage {
  const _OrderStage({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

class _StageDetailSheet extends StatelessWidget {
  const _StageDetailSheet({
    required this.stage,
    required this.order,
    required this.state,
  });

  final _OrderStage stage;
  final Map<String, dynamic> order;
  final TrackedOrderState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final orderId = order['_id']?.toString();
    final formattedDate = _formatDate(order['createdAt']);
    final status = order['status']?.toString().toLowerCase() ?? 'unknown';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Stage header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: stage.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        stage.icon,
                        color: stage.color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stage.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Order details
                _DetailSection(
                  title: 'Order Information',
                  items: [
                    _DetailItem(
                      label: 'Order ID',
                      value: orderId != null ? _readableOrderId(orderId) : 'N/A',
                      icon: Icons.receipt_long_rounded,
                    ),
                    if (formattedDate != null)
                      _DetailItem(
                        label: 'Order Date',
                        value: formattedDate,
                        icon: Icons.calendar_today_rounded,
                      ),
                    _DetailItem(
                      label: 'Current Status',
                      value: status.toUpperCase(),
                      icon: Icons.info_outline_rounded,
                    ),
                  ],
                ),

                // Location details
                if (order['pickupLocation'] != null ||
                    order['dropoffLocation'] != null) ...[
                  const SizedBox(height: 24),
                  _DetailSection(
                    title: 'Location Details',
                    items: [
                      if (order['pickupLocation'] != null)
                        _DetailItem(
                          label: 'Pickup Location',
                          value: _formatLocation(order['pickupLocation']),
                          icon: Icons.location_on_rounded,
                        ),
                      if (order['dropoffLocation'] != null)
                        _DetailItem(
                          label: 'Drop-off Location',
                          value: _formatLocation(order['dropoffLocation']),
                          icon: Icons.flag_rounded,
                        ),
                    ],
                  ),
                ],

                // Driver details
                if (order['driverId'] != null) ...[
                  const SizedBox(height: 24),
                  _DetailSection(
                    title: 'Driver Information',
                    items: [
                      _DetailItem(
                        label: 'Driver Name',
                        value: order['driverId']['name'] ?? 'N/A',
                        icon: Icons.person_rounded,
                      ),
                      if (order['driverId']['phoneNumber'] != null)
                        _DetailItem(
                          label: 'Phone Number',
                          value: _formatPhone(order['driverId']['phoneNumber']) ??
                              'N/A',
                          icon: Icons.phone_rounded,
                        ),
                      if (order['driverId']['vehicleType'] != null)
                        _DetailItem(
                          label: 'Vehicle Type',
                          value: order['driverId']['vehicleType'] ?? 'N/A',
                          icon: Icons.directions_car_rounded,
                        ),
                    ],
                  ),
                ],

                // Route information
                if (state.distanceMeters != null) ...[
                  const SizedBox(height: 24),
                  _DetailSection(
                    title: 'Route Information',
                    items: [
                      _DetailItem(
                        label: 'Distance',
                        value: '${(state.distanceMeters! / 1000).toStringAsFixed(2)} km',
                        icon: Icons.straighten_rounded,
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Close'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_DetailItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.map((item) {
              final isLast = items.last == item;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant.withOpacity(0.2),
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.value,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DetailItem {
  const _DetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noActiveOrders,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.loading,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

Marker _buildMarker({
  required LatLng point,
  required Color color,
  required IconData icon,
  double size = 44,
}) {
  return Marker(
    point: point,
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(
              color: color,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        Icon(icon, color: color, size: size * 0.6),
      ],
    ),
  );
}

const LatLng _kDefaultMapCenter = LatLng(31.9522, 35.2332);

LatLng? _calculateCenter(LatLng? first, LatLng? second) {
  if (first == null && second == null) return null;
  if (first == null) return second;
  if (second == null) return first;
  return LatLng(
    (first.latitude + second.latitude) / 2,
    (first.longitude + second.longitude) / 2,
  );
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows
        .where((row) => row.value != null && row.value.toString().isNotEmpty);
    if (visibleRows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...visibleRows,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String? label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                Text(
                  value.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      backgroundColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

String? _formatDate(dynamic value) {
  DateTime? dateTime;

  if (value is String) {
    dateTime = DateTime.tryParse(value);
  } else if (value is DateTime) {
    dateTime = value;
  } else if (value is Map && value.containsKey('\$date')) {
    final rawDate = value['\$date'];
    if (rawDate is Map && rawDate.containsKey('\$numberLong')) {
      final millis = int.tryParse(rawDate['\$numberLong'].toString());
      if (millis != null) {
        dateTime =
            DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
      }
    } else if (rawDate is String) {
      dateTime = DateTime.tryParse(rawDate);
    }
  }

  if (dateTime == null) {
    return null;
  }

  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

String _formatLocation(Map<String, dynamic>? location) {
  if (location == null || location.isEmpty) return 'Not available';
  if (location['address'] != null &&
      location['address'].toString().isNotEmpty) {
    return location['address'].toString();
  }
  final lat = location['lat'];
  final lng = location['lng'];
  if (lat == null || lng == null) return 'Not available';
  final latValue = lat is num ? lat.toDouble() : double.tryParse('$lat');
  final lngValue = lng is num ? lng.toDouble() : double.tryParse('$lng');
  if (latValue == null || lngValue == null) return 'Not available';
  return '${latValue.toStringAsFixed(5)}, ${lngValue.toStringAsFixed(5)}';
}

String? _formatPhone(dynamic phone) {
  if (phone == null) return null;
  final phoneStr = phone.toString();
  if (phoneStr.isEmpty) return null;
  return phoneStr;
}

String _readableOrderId(String orderId) {
  if (orderId.length <= 6) return '#${orderId.toUpperCase()}';
  return '#${orderId.substring(orderId.length - 6).toUpperCase()}';
}