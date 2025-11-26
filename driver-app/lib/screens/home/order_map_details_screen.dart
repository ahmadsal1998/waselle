import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../../view_models/map_style_view_model.dart';

class OrderMapDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderMapDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Get pickup and dropoff locations
    final pickup = order['pickupLocation'];
    final dropoff = order['dropoffLocation'];

    if (pickup == null || dropoff == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.orderDetails)),
        body: const Center(
          child: Text('Location data not available'),
        ),
      );
    }

    final pickupLat = _toDouble(pickup['lat']);
    final pickupLng = _toDouble(pickup['lng']);
    final dropoffLat = _toDouble(dropoff['lat']);
    final dropoffLng = _toDouble(dropoff['lng']);

    if (pickupLat == null || pickupLng == null || 
        dropoffLat == null || dropoffLng == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.orderDetails)),
        body: const Center(
          child: Text('Invalid location coordinates'),
        ),
      );
    }

    final pickupLocation = LatLng(pickupLat, pickupLng);
    final dropoffLocation = LatLng(dropoffLat, dropoffLng);

    // Calculate center point
    final center = LatLng(
      (pickupLat + dropoffLat) / 2,
      (pickupLng + dropoffLng) / 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13.0,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                Consumer<MapStyleViewModel>(
                  builder: (context, mapStyleViewModel, _) {
                    final subdomains = mapStyleViewModel.getSubdomains();
                    return TileLayer(
                      urlTemplate: mapStyleViewModel.getUrlTemplate(),
                      userAgentPackageName: 'com.wassle.driverapp',
                      maxZoom: mapStyleViewModel.getMaxZoom().toDouble(),
                      subdomains: subdomains ?? const ['a', 'b', 'c'],
                      retinaMode: mapStyleViewModel.useRetinaTiles()
                          ? RetinaMode.isHighDensity(context)
                          : false,
                    );
                  },
                ),
                // Route line between pickup and dropoff
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [pickupLocation, dropoffLocation],
                      strokeWidth: 4.0,
                      color: theme.colorScheme.primary,
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Pickup marker
                    Marker(
                      point: pickupLocation,
                      width: 50,
                      height: 50,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PICKUP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dropoff marker
                    Marker(
                      point: dropoffLocation,
                      width: 50,
                      height: 50,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.flag,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'DROPOFF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
          ),
          // Location details card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pickup['address']?.toString() ?? 
                            '${pickupLat.toStringAsFixed(6)}, ${pickupLng.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Dropoff location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.flag,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dropoff Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dropoff['address']?.toString() ?? 
                            '${dropoffLat.toStringAsFixed(6)}, ${dropoffLng.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

