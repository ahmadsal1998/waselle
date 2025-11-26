import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';

import '../../view_models/map_style_view_model.dart';
import '../../view_models/order_tracking_view_model.dart';

class OrderMapViewScreen extends StatelessWidget {
  const OrderMapViewScreen({
    super.key,
    required this.order,
    required this.state,
  });

  final Map<String, dynamic> order;
  final TrackedOrderState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final mapStyleProvider = context.watch<MapStyleViewModel>();

    final orderId = order['_id']?.toString();
    final routePoints = state.routePoints;
    final isLoadingRoute = state.isRouteLoading;
    final distanceMeters = state.distanceMeters;
    final pickup = _toLatLng(order['pickupLocation']);
    final dropoff = _toLatLng(order['dropoffLocation']);
    final center = _calculateCenter(
          state.driverLocation ?? pickup,
          state.customerLocation ?? dropoff,
        ) ??
        pickup ??
        dropoff ??
        const LatLng(31.9522, 35.2332);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.trackOrder} - ${_readableOrderId(orderId ?? '')}',
        ),
        actions: [
          if (distanceMeters != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.straighten_rounded,
                        size: 18,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(distanceMeters / 1000).toStringAsFixed(1)} km',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: state.mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onMapReady: () {
                state.markMapReady();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: mapStyleProvider.getUrlTemplate(),
                userAgentPackageName: 'com.wassle.userapp',
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
                      strokeWidth: 6.0,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (state.driverLocation != null)
                    _buildMarker(
                      point: state.driverLocation!,
                      color: Colors.green,
                      icon: Icons.delivery_dining_rounded,
                      label: 'Driver',
                    ),
                  if (state.customerLocation != null)
                    _buildMarker(
                      point: state.customerLocation!,
                      color: Colors.blue,
                      icon: Icons.person_pin_circle_rounded,
                      label: 'You',
                    ),
                  if (pickup != null)
                    _buildMarker(
                      point: pickup!,
                      color: Colors.orange,
                      icon: Icons.store_rounded,
                      size: 36,
                      label: 'Pickup',
                    ),
                  if (dropoff != null)
                    _buildMarker(
                      point: dropoff!,
                      color: Colors.red,
                      icon: Icons.location_on_rounded,
                      size: 36,
                      label: 'Drop-off',
                    ),
                ],
              ),
              if (mapStyleProvider.getAttribution()?.isNotEmpty ?? false)
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
          // Bottom info card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order ${_readableOrderId(orderId ?? '')}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatStatus(order['status']?.toString() ?? ''),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (order['driverId'] != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Driver',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order['driverId']['name'] ?? 'N/A',
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
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildMarker({
    required LatLng point,
    required Color color,
    required IconData icon,
    double size = 48,
    String? label,
  }) {
    return Marker(
      point: point,
      width: size + (label != null ? 60 : 0),
      height: size + (label != null ? 30 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          if (label != null) const SizedBox(height: 4),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
              border: Border.all(
                color: color,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: size * 0.6),
          ),
        ],
      ),
    );
  }

  LatLng? _toLatLng(dynamic data) {
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

  LatLng? _calculateCenter(LatLng? first, LatLng? second) {
    if (first == null && second == null) return null;
    if (first == null) return second;
    if (second == null) return first;
    return LatLng(
      (first.latitude + second.latitude) / 2,
      (first.longitude + second.longitude) / 2,
    );
  }

  String _readableOrderId(String orderId) {
    if (orderId.length <= 6) return '#${orderId.toUpperCase()}';
    return '#${orderId.substring(orderId.length - 6).toUpperCase()}';
  }

  String _formatStatus(String status) {
    return status.toUpperCase();
  }
}

