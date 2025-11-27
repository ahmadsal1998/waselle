import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';
import 'package:geocoding/geocoding.dart';

import '../../view_models/order_view_model.dart';
import '../../view_models/locale_view_model.dart';
import '../../theme/app_theme.dart';

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(l10n.orderHistory),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<OrderViewModel>(
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
          
          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _loadOrders(orderProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      l10n.noOrdersYet,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        
          return RefreshIndicator(
            onRefresh: () => _loadOrders(orderProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: orders.length,
              itemBuilder: (context, index) {
              final order = orders[index];
              final statusRaw = order['status']?.toString().toLowerCase() ?? 'unknown';
              final price = order['price']?.toString() ?? '--';
              final createdAt = DateTime.tryParse(order['createdAt'] ?? '');
              final createdText = createdAt != null
                  ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                  : l10n.unknownDate;
              final orderId = order['_id']?.toString() ?? '---';
              final shortOrderId = orderId.length > 6 ? orderId.substring(0, 6) : orderId;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  color: theme.colorScheme.surface,
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _statusColor(statusRaw).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(statusRaw),
                        color: _statusColor(statusRaw),
                        size: 24,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.orderNumber(shortOrderId),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    createdText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Consumer<LocaleViewModel>(
                          builder: (context, localeViewModel, _) {
                            final statusText = _getStatusText(statusRaw, l10n, localeViewModel.isArabic);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: _statusColor(statusRaw).withOpacity(0.15),
                                border: Border.all(
                                  color: _statusColor(statusRaw).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(statusRaw),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '₪$price',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    children: [
                      // Divider with spacing
                      Divider(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        height: 24,
                      ),
                      
                      // Pickup Location
                      _buildOrderDetailRow(
                        icon: Icons.location_on,
                        iconColor: AppTheme.primaryColor,
                        label: l10n.pickupLocation,
                        child: _LocationText(
                          location: order['pickupLocation'],
                          addressCache: _addressCache,
                        ),
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      
                      // Dropoff Location
                      _buildOrderDetailRow(
                        icon: Icons.location_on,
                        iconColor: AppTheme.successColor,
                        label: l10n.dropoffLocation,
                        child: _LocationText(
                          location: order['dropoffLocation'],
                          addressCache: _addressCache,
                        ),
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      
                      // Additional Details Section
                      if (order['type'] != null ||
                          order['orderCategory'] != null ||
                          order['vehicleType'] != null ||
                          order['deliveryType'] != null ||
                          order['senderName'] != null ||
                          order['phone'] != null ||
                          order['senderPhoneNumber'] != null ||
                          order['distance'] != null ||
                          order['estimatedTime'] != null ||
                          (order['deliveryNotes'] != null && order['deliveryNotes'].toString().isNotEmpty)) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (order['type'] != null) ...[
                                _buildOrderDetailRow(
                                  icon: Icons.category,
                                  iconColor: Colors.purple,
                                  label: l10n.orderType,
                                  child: Text(
                                    order['type'] == 'send' 
                                        ? (l10n.sendRequest) 
                                        : (l10n.receiveRequest),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (order['orderCategory'] != null) ...[
                                _buildOrderDetailRow(
                                  icon: Icons.label,
                                  iconColor: AppTheme.warningColor,
                                  label: l10n.category,
                                  child: Text(
                                    order['orderCategory'].toString(),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (order['vehicleType'] != null) ...[
                                _buildOrderDetailRow(
                                  icon: Icons.directions_car,
                                  iconColor: Colors.teal,
                                  label: l10n.vehicle,
                                  child: Text(
                                    _getVehicleTypeText(order['vehicleType'].toString(), l10n),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (order['deliveryType'] != null) ...[
                                _buildOrderDetailRow(
                                  icon: Icons.local_shipping,
                                  iconColor: Colors.indigo,
                                  label: l10n.deliveryType,
                                  child: Text(
                                    order['deliveryType'] == 'internal'
                                        ? l10n.internalDelivery
                                        : l10n.externalDelivery,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (order['senderName'] != null) ...[
                                _buildOrderDetailRow(
                                  icon: Icons.person,
                                  iconColor: Colors.brown,
                                  label: l10n.senderName,
                                  child: Text(
                                    order['senderName'].toString(),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (order['phone'] != null || order['senderPhoneNumber'] != null) ...[
                                _buildOrderDetailRow(
                                  icon: Icons.phone,
                                  iconColor: Colors.blueGrey,
                                  label: l10n.phone,
                                  child: Text(
                                    order['phone']?.toString() ?? 
                                    order['senderPhoneNumber']?.toString() ?? 
                                    '--',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (order['distance'] != null) ...[
                                _buildOrderDetailRow(
                                  icon: Icons.straighten,
                                  iconColor: Colors.deepPurple,
                                  label: l10n.distance,
                                  child: Text(
                                    l10n.kilometers(order['distance'].toString()),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (order['estimatedTime'] != null) ...[
                                _buildOrderDetailRow(
                                  icon: Icons.access_time,
                                  iconColor: Colors.amber,
                                  label: l10n.estimatedTime,
                                  child: Text(
                                    l10n.minutes(order['estimatedTime'].toString()),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (order['deliveryNotes'] != null && order['deliveryNotes'].toString().isNotEmpty) ...[
                                _buildOrderDetailRow(
                                  icon: Icons.note,
                                  iconColor: Colors.grey,
                                  label: l10n.notes,
                                  child: Text(
                                    order['deliveryNotes'].toString(),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  theme: theme,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'new_price_pending':
        return AppTheme.warningColor; // Orange
      case 'accepted':
        return AppTheme.primaryColor; // Blue
      case 'on_the_way':
        return Colors.blue.shade600;
      case 'delivered':
        return AppTheme.successColor; // Green
      case 'cancelled':
        return AppTheme.errorColor; // Red
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'new_price_pending':
        return Icons.pending_outlined;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'on_the_way':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
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
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
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
    final theme = Theme.of(context);
    return Text(
      _displayText,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
