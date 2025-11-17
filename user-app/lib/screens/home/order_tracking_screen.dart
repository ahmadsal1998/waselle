import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';

import '../../view_models/location_view_model.dart';
import '../../view_models/map_style_view_model.dart';
import '../../view_models/order_view_model.dart';
import '../../view_models/order_tracking_view_model.dart';

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

class _TrackedOrderCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final orderId = order['_id']?.toString();
    if (orderId == null) {
      return const SizedBox.shrink();
    }

    final routePoints = state.routePoints;
    final isLoadingRoute = state.isRouteLoading;
    final distanceMeters = state.distanceMeters;
    final formattedDate = _formatDate(order['createdAt']);
    final status = order['status']?.toString() ?? 'Unknown';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ${_readableOrderId(orderId)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Chip(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  label: Text(
                    status,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: state.mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 13.0,
                      minZoom: 5.0,
                      maxZoom: 18.0,
                      onMapReady: () {
                        // Mark map as ready and move to any pending center
                        state.markMapReady();
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: mapStyleProvider.getUrlTemplate(),
                        userAgentPackageName: 'com.delivery.userapp',
                        maxZoom: mapStyleProvider.getMaxZoom().toDouble(),
                        subdomains: mapStyleProvider.getSubdomains() ??
                            const ['a', 'b', 'c'],
                        retinaMode: mapStyleProvider.useRetinaTiles()
                            ? RetinaMode.isHighDensity(context)
                            : false,
                      ),
                      if (routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              strokeWidth: 4.5,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (state.driverLocation != null)
                            _buildMarker(
                              point: state.driverLocation!,
                              color: Colors.green,
                              icon: Icons.delivery_dining,
                            ),
                          if (state.customerLocation != null)
                            _buildMarker(
                              point: state.customerLocation!,
                              color: Colors.blue,
                              icon: Icons.person_pin_circle,
                            ),
                          if (pickup != null)
                            _buildMarker(
                              point: pickup!,
                              color: Colors.orange,
                              icon: Icons.store_mall_directory,
                              size: 30,
                            ),
                          if (dropoff != null)
                            _buildMarker(
                              point: dropoff!,
                              color: Colors.red,
                              icon: Icons.location_on,
                              size: 30,
                            ),
                        ],
                      ),
                      if (mapStyleProvider.getAttribution()?.isNotEmpty ??
                          false)
                        RichAttributionWidget(
                          alignment: AttributionAlignment.bottomRight,
                          attributions: [
                            TextSourceAttribution(
                              mapStyleProvider.getAttribution()!,
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (isLoadingRoute)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black12,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
            if (order['driverId'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _InfoSection(
                  title: 'Driver',
                  rows: [
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: 'Name',
                      value: order['driverId']['name'],
                    ),
                    _InfoRow(
                      icon: Icons.phone_android,
                      label: 'Phone',
                      value: _formatPhone(order['driverId']['phoneNumber']),
                    ),
                    _InfoRow(
                      icon: Icons.directions_car_filled_outlined,
                      label: 'Vehicle',
                      value: order['driverId']['vehicleType'] ??
                          order['vehicleType'],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
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
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.18),
          ),
        ),
        Icon(icon, color: color, size: size * 0.65),
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