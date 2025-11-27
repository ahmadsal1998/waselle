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
import '../../view_models/locale_view_model.dart';
import '../../widgets/responsive_button.dart';
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
    // Watch OrderViewModel to ensure UI updates when order status changes
    final body = Consumer3<OrderTrackingViewModel, MapStyleViewModel, OrderViewModel>(
      builder: (context, trackingViewModel, mapStyleProvider, orderViewModel, _) {
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                key: ValueKey('order_${orderId}_${order['status']}'), // Force rebuild on status change
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
    super.key,
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
  bool _isOrderDetailsExpanded = false;
  bool _isMapVisible = true;
  bool _isDriverInfoVisible = false;
  
  // Watch OrderViewModel to get latest order data
  @override
  Widget build(BuildContext context) {
    // Get the latest order data from OrderViewModel to ensure we have the most up-to-date status
    final orderViewModel = Provider.of<OrderViewModel>(context, listen: true);
    final orderId = widget.order['_id']?.toString();
    if (orderId == null) {
      return const SizedBox.shrink();
    }
    
    // Get the latest order data (may have updated status)
    final latestOrder = orderViewModel.getActiveOrderById(orderId) ?? widget.order;

    final routePoints = widget.state.routePoints;
    final isLoadingRoute = widget.state.isRouteLoading;
    final distanceMeters = widget.state.distanceMeters;
    final formattedDate = _formatDate(latestOrder['createdAt']);
    final status = latestOrder['status']?.toString().toLowerCase() ?? 'unknown';

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
          // Compact Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order ${_readableOrderId(latestOrder['_id']?.toString() ?? '')}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Consumer<LocaleViewModel>(
                            builder: (context, localeViewModel, _) {
                              final statusText = _getStatusText(status, l10n, localeViewModel.isArabic);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status, colorScheme).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  statusText,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: _getStatusColor(status, colorScheme),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      if (formattedDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Price Proposal Section (shown when driver has proposed a price)
          _PriceProposalSection(
            order: latestOrder,
            orderId: orderId,
          ),

          // Map Section (Collapsible) - Directly below order number
          Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isMapVisible = !_isMapVisible;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.2),
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.map_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.mapView,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      Icon(
                        _isMapVisible
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isMapVisible
                    ? GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => OrderMapViewScreen(
                                order: latestOrder,
                                state: widget.state,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 200,
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
                        userAgentPackageName: 'com.wassle.userapp',
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
                  )
                    : const SizedBox.shrink(),
              ),
            ],
          ),

          // Order Details Panel (Collapsible)
          _OrderDetailsPanel(
            order: latestOrder,
            isExpanded: _isOrderDetailsExpanded,
            onToggle: () {
              setState(() {
                _isOrderDetailsExpanded = !_isOrderDetailsExpanded;
              });
            },
          ),

          // Order Stages Timeline Toggle Button
          InkWell(
            onTap: () {
              setState(() {
                _isOrderProgressVisible = !_isOrderProgressVisible;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.2),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.2),
                  ),
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timeline_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.orderProgress,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  Icon(
                    _isOrderProgressVisible
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Order Stages Timeline (Collapsible)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isOrderProgressVisible
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _OrderStageTimeline(
                      currentStatus: status,
                      order: latestOrder,
                      state: widget.state,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Driver Info Section (Collapsible)
          if (latestOrder['driverId'] != null) ...[
            InkWell(
              onTap: () {
                setState(() {
                  _isDriverInfoVisible = !_isDriverInfoVisible;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.2),
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.driverInformation,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    Icon(
                      _isDriverInfoVisible
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isDriverInfoVisible
                  ? Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        children: [
                          _InfoSection(
                            title: l10n.driverInformation,
                            rows: [
                              _InfoRow(
                                icon: Icons.person_outline_rounded,
                                label: 'Name',
                                value: latestOrder['driverId']['name'],
                              ),
                              _InfoRow(
                                icon: Icons.phone_android_rounded,
                                label: 'Phone',
                                value: _formatPhone(latestOrder['driverId']['phoneNumber']),
                              ),
                              _InfoRow(
                                icon: Icons.directions_car_filled_rounded,
                                label: 'Vehicle',
                                value: latestOrder['driverId']['vehicleType'] ??
                                    latestOrder['vehicleType'],
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
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

  String _getStatusText(String status, AppLocalizations l10n, bool isArabic) {
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.pending;
      case 'accepted':
        return l10n.orderAccepted;
      case 'on_the_way':
        return l10n.onTheWay;
      case 'delivered':
        return l10n.delivered;
      case 'cancelled':
        return l10n.cancelled;
      default:
        return status.toUpperCase();
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
    final l10n = AppLocalizations.of(context)!;
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
                    title: l10n.driverInformation,
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
                ResponsiveButton.filled(
                  context: context,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icons.close_rounded,
                  borderRadius: 16,
                  child: const Text(
                    'Close',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
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

class _OrderDetailsPanel extends StatelessWidget {
  const _OrderDetailsPanel({
    required this.order,
    required this.isExpanded,
    required this.onToggle,
  });

  final Map<String, dynamic> order;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Default view: Delivery Type, From, To
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Delivery Type
                if (order['deliveryType'] != null)
                  _buildDetailRow(
                    context: context,
                    icon: Icons.local_shipping,
                    iconColor: Colors.indigo,
                    label: l10n.deliveryType,
                    value: order['deliveryType'] == 'internal'
                        ? l10n.internalDelivery
                        : l10n.externalDelivery,
                  ),
                if (order['deliveryType'] != null) const SizedBox(height: 12),
                // From (Pickup Location)
                if (order['pickupLocation'] != null)
                  _buildDetailRow(
                    context: context,
                    icon: Icons.call_made,
                    iconColor: Colors.blue,
                    label: l10n.from ?? 'From',
                    value: _formatLocationShort(order['pickupLocation']),
                  ),
                if (order['pickupLocation'] != null) const SizedBox(height: 12),
                // To (Dropoff Location)
                if (order['dropoffLocation'] != null)
                  _buildDetailRow(
                    context: context,
                    icon: Icons.call_received,
                    iconColor: Colors.green,
                    label: l10n.to ?? 'To',
                    value: _formatLocationShort(order['dropoffLocation']),
                  ),
              ],
            ),
          ),
          // Expand/Collapse Button
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isExpanded
                        ? (l10n.viewLess ?? 'View Less')
                        : (l10n.viewMore ?? 'View More'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Expanded details
          if (isExpanded)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 12),
                    // Order Type
                    if (order['type'] != null) ...[
                      _buildDetailRow(
                        context: context,
                        icon: Icons.category,
                        iconColor: Colors.purple,
                        label: l10n.orderType,
                        value: order['type'] == 'send'
                            ? l10n.sendRequest
                            : l10n.receiveRequest,
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Order Category
                    if (order['orderCategory'] != null) ...[
                      _buildDetailRow(
                        context: context,
                        icon: Icons.label,
                        iconColor: Colors.orange,
                        label: l10n.category,
                        value: order['orderCategory'].toString(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Vehicle Type
                    if (order['vehicleType'] != null) ...[
                      _buildDetailRow(
                        context: context,
                        icon: Icons.directions_car,
                        iconColor: Colors.teal,
                        label: l10n.vehicle,
                        value: _getVehicleTypeText(order['vehicleType'].toString(), l10n),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Sender Name
                    if (order['senderName'] != null) ...[
                      _buildDetailRow(
                        context: context,
                        icon: Icons.person,
                        iconColor: Colors.brown,
                        label: l10n.senderName,
                        value: order['senderName'].toString(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Phone
                    if (order['phone'] != null || order['senderPhoneNumber'] != null) ...[
                      _buildDetailRow(
                        context: context,
                        icon: Icons.phone,
                        iconColor: Colors.blueGrey,
                        label: l10n.phone,
                        value: order['phone']?.toString() ??
                            order['senderPhoneNumber']?.toString() ??
                            '--',
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Price - show finalPrice if proposed/accepted, otherwise show estimated price
                    Builder(
                      builder: (context) {
                        final priceStatus = order['priceStatus']?.toString().toLowerCase();
                        final finalPrice = order['finalPrice'];
                        final displayPrice = (priceStatus == 'proposed' || priceStatus == 'accepted') && finalPrice != null
                            ? finalPrice
                            : order['price'] ?? order['estimatedPrice'];
                        if (displayPrice == null) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            _buildDetailRow(
                              context: context,
                              icon: Icons.attach_money,
                              iconColor: Colors.green,
                              label: (priceStatus == 'proposed' || priceStatus == 'accepted') && finalPrice != null
                                  ? l10n.finalPrice
                                  : l10n.price,
                              value: '₪${displayPrice}',
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                    // Distance
                    if (order['distance'] != null) ...[
                      _buildDetailRow(
                        context: context,
                        icon: Icons.straighten,
                        iconColor: Colors.deepPurple,
                        label: l10n.distance,
                        value: l10n.kilometers(order['distance'].toString()),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Estimated Time
                    if (order['estimatedTime'] != null) ...[
                      _buildDetailRow(
                        context: context,
                        icon: Icons.access_time,
                        iconColor: Colors.amber,
                        label: l10n.estimatedTime,
                        value: l10n.minutes(order['estimatedTime'].toString()),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Delivery Notes
                    if (order['deliveryNotes'] != null &&
                        order['deliveryNotes'].toString().isNotEmpty) ...[
                      _buildDetailRow(
                        context: context,
                        icon: Icons.note,
                        iconColor: Colors.grey,
                        label: l10n.notes,
                        value: order['deliveryNotes'].toString(),
                        isMultiline: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: isMultiline ? null : 2,
                overflow: isMultiline ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatLocationShort(Map<String, dynamic>? location) {
    if (location == null || location.isEmpty) return 'Not available';
    if (location['address'] != null &&
        location['address'].toString().isNotEmpty) {
      final address = location['address'].toString();
      // Show first 50 characters if address is long
      return address.length > 50 ? '${address.substring(0, 50)}...' : address;
    }
    final lat = location['lat'];
    final lng = location['lng'];
    if (lat == null || lng == null) return 'Not available';
    final latValue = lat is num ? lat.toDouble() : double.tryParse('$lat');
    final lngValue = lng is num ? lng.toDouble() : double.tryParse('$lng');
    if (latValue == null || lngValue == null) return 'Not available';
    return '${latValue.toStringAsFixed(4)}, ${lngValue.toStringAsFixed(4)}';
  }

  String _getVehicleTypeText(String vehicleType, AppLocalizations l10n) {
    switch (vehicleType.toLowerCase()) {
      case 'bike':
        return l10n.bike;
      case 'car':
        return l10n.car;
      case 'cargo':
        return l10n.cargo;
      default:
        return vehicleType;
    }
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

/// Widget to show price proposal from driver and allow user to accept/reject
class _PriceProposalSection extends StatefulWidget {
  const _PriceProposalSection({
    required this.order,
    required this.orderId,
  });

  final Map<String, dynamic> order;
  final String orderId;

  @override
  State<_PriceProposalSection> createState() => _PriceProposalSectionState();
}

class _PriceProposalSectionState extends State<_PriceProposalSection> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final priceStatus = widget.order['priceStatus']?.toString().toLowerCase();
    final finalPrice = widget.order['finalPrice'];
    final estimatedPrice = widget.order['estimatedPrice'];
    final orderStatus = widget.order['status']?.toString().toLowerCase();
    
    // Only show if price status is 'proposed' and order is accepted (not yet on_the_way)
    if (priceStatus != 'proposed' || orderStatus != 'accepted') {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.priceProposalReceived,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.shade800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.driverProposedPrice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Price comparison
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Estimated price
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.estimatedPrice,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${estimatedPrice ?? 0} ₪',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                              decoration: TextDecoration.lineThrough,
                            ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                // Final price
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.finalPrice,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${finalPrice ?? 0} ₪',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Accept/Reject buttons
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            Row(
              children: [
                // Reject button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _respondToPrice(false),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(l10n.rejectPrice),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Accept button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _respondToPrice(true),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.acceptPrice),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _respondToPrice(bool accept) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
      final success = await orderViewModel.respondToPrice(
        orderId: widget.orderId,
        accept: accept,
      );

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? l10n.priceAcceptedSuccess : l10n.priceRejectedSuccess,
            ),
            backgroundColor: accept ? Colors.green : Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToRespondToPrice),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToRespondToPrice),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}