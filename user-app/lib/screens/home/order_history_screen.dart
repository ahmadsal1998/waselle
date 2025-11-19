import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';
import 'package:geocoding/geocoding.dart';

import '../../view_models/order_view_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = false;
  bool _isInitialized = false;
  // Cache to store geocoded addresses by coordinate key
  final Map<String, String> _addressCache = {};

  Future<void> _loadOrders(OrderViewModel orderProvider) async {
    setState(() => _isLoading = true);
    await orderProvider.fetchOrders();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      final orderProvider = Provider.of<OrderViewModel>(context, listen: false);
      _loadOrders(orderProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderViewModel>(
      builder: (context, orderProvider, _) {
        final orders = orderProvider.orders;

        if (_isLoading && orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final l10n = AppLocalizations.of(context)!;
        
        if (orders.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _loadOrders(orderProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                const Icon(Icons.inbox, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    l10n.noOrdersYet,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _loadOrders(orderProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final status =
                  order['status']?.toString().toUpperCase() ?? 'UNKNOWN';
              final price = order['price']?.toString() ?? '--';
              final createdAt = DateTime.tryParse(order['createdAt'] ?? '');
              final createdText = createdAt != null
                  ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                  : l10n.unknownDate;

              // Alternate background colors: shade200 for even indices (starting with first card), shade100 for odd indices
              final cardColor = index % 2 == 0
                  ? Colors.grey.shade100
                  : Colors.grey.shade50;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.orderNumber(order['_id']?.toString().substring(0, 6) ?? '---'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: _statusColor(status).withOpacity(0.15),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.call_made,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LocationText(
                              location: order['pickupLocation'],
                              addressCache: _addressCache,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.call_received,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LocationText(
                              location: order['dropoffLocation'],
                              addressCache: _addressCache,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${l10n.price}: \$$price',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            createdText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'on_the_way':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

}

// Widget to handle async loading of location names
class _LocationText extends StatefulWidget {
  const _LocationText({
    required this.location,
    required this.addressCache,
  });

  final Map<String, dynamic>? location;
  final Map<String, String> addressCache;

  @override
  State<_LocationText> createState() => _LocationTextState();
}

class _LocationTextState extends State<_LocationText> {
  String _displayText = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocationName();
  }

  Future<void> _loadLocationName() async {
    if (widget.location == null) {
      setState(() {
        _displayText = 'Unknown location';
        _isLoading = false;
      });
      return;
    }

    final latValue = widget.location!['lat'];
    final lngValue = widget.location!['lng'];
    
    if (latValue == null || lngValue == null) {
      setState(() {
        _displayText = 'Unknown location';
        _isLoading = false;
      });
      return;
    }

    final lat = latValue is num 
        ? latValue.toDouble() 
        : double.tryParse('$latValue');
    final lng = lngValue is num 
        ? lngValue.toDouble() 
        : double.tryParse('$lngValue');

    if (lat == null || lng == null) {
      setState(() {
        _displayText = 'Unknown location';
        _isLoading = false;
      });
      return;
    }

    // Show coordinates initially while loading
    setState(() {
      _displayText = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    });

    try {
      final areaName = await _getAreaName(lat, lng, widget.addressCache);
      if (mounted) {
        setState(() {
          _displayText = areaName;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Keep coordinates as fallback
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _getAreaName(
    double latitude,
    double longitude,
    Map<String, String> cache,
  ) async {
    // Create a cache key from coordinates (rounded to 4 decimal places)
    final cacheKey = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    
    // Check cache first
    if (cache.containsKey(cacheKey)) {
      return cache[cacheKey]!;
    }

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final areaName = _formatPlacemarkAddress(placemark, latitude, longitude);
        
        // Cache the result
        cache[cacheKey] = areaName;
        return areaName;
      } else {
        // Fallback to coordinates if no placemark found
        final fallback = '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
        cache[cacheKey] = fallback;
        return fallback;
      }
    } catch (e) {
      // Fallback to coordinates on error
      final fallback = '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
      cache[cacheKey] = fallback;
      return fallback;
    }
  }

  String _formatPlacemarkAddress(
    Placemark placemark,
    double latitude,
    double longitude,
  ) {
    final parts = <String>[];
    
    // Prioritize locality (city/town), subLocality (neighborhood), and administrativeArea (region)
    if (placemark.locality?.isNotEmpty ?? false) {
      parts.add(placemark.locality!);
    }
    
    if (placemark.subLocality?.isNotEmpty ?? false) {
      // If we have both locality and subLocality, format as "City - Neighborhood"
      if (parts.isNotEmpty) {
        parts.insert(parts.length - 1, placemark.subLocality!);
        return parts.join(' – ');
      } else {
        parts.add(placemark.subLocality!);
      }
    }
    
    // Add administrative area if we don't have enough info
    if (parts.length < 2 && (placemark.administrativeArea?.isNotEmpty ?? false)) {
      if (parts.isEmpty) {
        parts.add(placemark.administrativeArea!);
      } else {
        parts.add(placemark.administrativeArea!);
        return parts.join(' – ');
      }
    }
    
    // If we have parts, return them joined
    if (parts.isNotEmpty) {
      return parts.join(' – ');
    }
    
    // Fallback to coordinates if no meaningful address parts found
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: const TextStyle(fontSize: 14),
    );
  }
}
