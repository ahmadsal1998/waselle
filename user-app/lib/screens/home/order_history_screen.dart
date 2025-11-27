import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';
import 'package:geocoding/geocoding.dart';

import '../../view_models/order_view_model.dart';
import '../../view_models/locale_view_model.dart';

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
        final allOrders = orderProvider.orders;
        
        // Filter to show only submitted or completed orders, exclude cancelled/rejected
        final orders = allOrders.where((order) {
          final status = (order['status'] ?? '').toString().toLowerCase();
          // Include: pending, accepted, on_the_way, delivered, new_price_pending
          // Exclude: cancelled, price_rejected
          return status != 'cancelled' && status != 'price_rejected';
        }).toList();

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
              final statusRaw = order['status']?.toString().toLowerCase() ?? 'unknown';
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
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.orderNumber(order['_id']?.toString().substring(0, 6) ?? '---'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Consumer<LocaleViewModel>(
                        builder: (context, localeViewModel, _) {
                          final statusText = _getStatusText(statusRaw, l10n, localeViewModel.isArabic);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: _statusColor(statusRaw).withOpacity(0.15),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(statusRaw),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${l10n.price}: ₪$price',
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
                  children: [
                    _buildOrderDetailRow(
                      icon: Icons.call_made,
                      iconColor: Colors.blue,
                      label: l10n.pickupLocation,
                      child: _LocationText(
                        location: order['pickupLocation'],
                        addressCache: _addressCache,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildOrderDetailRow(
                      icon: Icons.call_received,
                      iconColor: Colors.green,
                      label: l10n.dropoffLocation,
                      child: _LocationText(
                        location: order['dropoffLocation'],
                        addressCache: _addressCache,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    if (order['type'] != null)
                      _buildOrderDetailRow(
                        icon: Icons.category,
                        iconColor: Colors.purple,
                        label: l10n.orderType,
                        child: Text(
                          order['type'] == 'send' 
                              ? (l10n.sendRequest) 
                              : (l10n.receiveRequest),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    if (order['orderCategory'] != null) ...[
                      const SizedBox(height: 8),
                      _buildOrderDetailRow(
                        icon: Icons.label,
                        iconColor: Colors.orange,
                        label: l10n.category,
                        child: Text(
                          order['orderCategory'].toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    if (order['vehicleType'] != null) ...[
                      const SizedBox(height: 8),
                      _buildOrderDetailRow(
                        icon: Icons.directions_car,
                        iconColor: Colors.teal,
                        label: l10n.vehicle,
                        child: Text(
                          _getVehicleTypeText(order['vehicleType'].toString(), l10n),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    if (order['deliveryType'] != null) ...[
                      const SizedBox(height: 8),
                      _buildOrderDetailRow(
                        icon: Icons.local_shipping,
                        iconColor: Colors.indigo,
                        label: l10n.deliveryType,
                        child: Text(
                          order['deliveryType'] == 'internal'
                              ? l10n.internalDelivery
                              : l10n.externalDelivery,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    if (order['senderName'] != null) ...[
                      const SizedBox(height: 8),
                      _buildOrderDetailRow(
                        icon: Icons.person,
                        iconColor: Colors.brown,
                        label: l10n.senderName,
                        child: Text(
                          order['senderName'].toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    if (order['phone'] != null || order['senderPhoneNumber'] != null) ...[
                      const SizedBox(height: 8),
                      _buildOrderDetailRow(
                        icon: Icons.phone,
                        iconColor: Colors.blueGrey,
                        label: l10n.phone,
                        child: Text(
                          order['phone']?.toString() ?? 
                          order['senderPhoneNumber']?.toString() ?? 
                          '--',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    if (order['distance'] != null) ...[
                      const SizedBox(height: 8),
                      _buildOrderDetailRow(
                        icon: Icons.straighten,
                        iconColor: Colors.deepPurple,
                        label: l10n.distance,
                        child: Text(
                          l10n.kilometers(order['distance'].toString()),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    if (order['estimatedTime'] != null) ...[
                      const SizedBox(height: 8),
                      _buildOrderDetailRow(
                        icon: Icons.access_time,
                        iconColor: Colors.amber,
                        label: l10n.estimatedTime,
                        child: Text(
                          l10n.minutes(order['estimatedTime'].toString()),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    if (order['deliveryNotes'] != null && order['deliveryNotes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildOrderDetailRow(
                        icon: Icons.note,
                        iconColor: Colors.grey,
                        label: l10n.notes,
                        child: Text(
                          order['deliveryNotes'].toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ],
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

  Widget _buildOrderDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ],
    );
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
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    // Don't access inherited widgets in initState
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load location name after dependencies are available
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadLocationName();
    }
  }

  Future<void> _loadLocationName() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (widget.location == null) {
      setState(() {
        _displayText = l10n.unknownLocation;
        _isLoading = false;
      });
      return;
    }

    final latValue = widget.location!['lat'];
    final lngValue = widget.location!['lng'];
    
    if (latValue == null || lngValue == null) {
      setState(() {
        _displayText = l10n.unknownLocation;
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
        _displayText = l10n.unknownLocation;
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
