import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';

import '../../view_models/order_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/locale_view_model.dart';
import '../../theme/app_theme.dart';
import '../../services/osm_geocoding_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  final bool showAppBar;
  
  const OrderHistoryScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _wasAuthenticated = false;
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
    
    // Check authentication state
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final isAuthenticated = authViewModel.isAuthenticated;
    
    // If user just logged in (wasn't authenticated before, but is now)
    if (!_wasAuthenticated && isAuthenticated) {
      _wasAuthenticated = true;
      // Reload orders when user logs in
      final orderProvider = Provider.of<OrderViewModel>(context, listen: false);
      _loadOrders(orderProvider);
      return;
    }
    
    _wasAuthenticated = isAuthenticated;
    
    // Initial load
    if (!_isInitialized) {
      _isInitialized = true;
      _wasAuthenticated = isAuthenticated;
      final orderProvider = Provider.of<OrderViewModel>(context, listen: false);
      _loadOrders(orderProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    final content = _OrderHistoryContent(
      isLoading: _isLoading,
      addressCache: _addressCache,
      loadOrders: _loadOrders,
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          // Modern Header matching driver app
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              boxShadow: ModernCardShadow.medium,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        l10n.orderHistory,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body Content
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _OrderHistoryContent extends StatelessWidget {
  final bool isLoading;
  final Map<String, String> addressCache;
  final Future<void> Function(OrderViewModel) loadOrders;

  const _OrderHistoryContent({
    required this.isLoading,
    required this.addressCache,
    required this.loadOrders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<OrderViewModel>(
      builder: (context, orderProvider, _) {
        final allOrders = orderProvider.orders;
        
        // Filter to show only submitted or completed orders, exclude cancelled/rejected
        final orders = allOrders.where((order) {
          final status = (order['status'] ?? '').toString().toLowerCase();
          // Include: pending, accepted, on_the_way, delivered
          // Exclude: cancelled, price_rejected
          return status != 'cancelled' && status != 'price_rejected';
        }).toList();

        if (isLoading && orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (orders.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => loadOrders(orderProvider),
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
          onRefresh: () => loadOrders(orderProvider),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderHistoryItem(
                order: order,
                addressCache: addressCache,
              );
            },
          ),
        );
      },
    );
  }
}

class _OrderHistoryItem extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, String> addressCache;

  const _OrderHistoryItem({
    required this.order,
    required this.addressCache,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
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
                        Flexible(
                          child: Text(
                            createdText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
            _OrderDetailRow(
              icon: Icons.location_on,
              iconColor: AppTheme.primaryColor,
              label: l10n.pickupLocation,
              child: _LocationText(
                location: order['pickupLocation'],
                addressCache: addressCache,
              ),
            ),
            const SizedBox(height: 16),
            
            // Dropoff Location
            _OrderDetailRow(
              icon: Icons.location_on,
              iconColor: AppTheme.successColor,
              label: l10n.dropoffLocation,
              child: _LocationText(
                location: order['dropoffLocation'],
                addressCache: addressCache,
              ),
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order['type'] != null) ...[
                      _OrderDetailRow(
                        icon: Icons.category,
                        iconColor: Colors.purple,
                        label: l10n.orderType,
                        child: Text(
                          order['type'] == 'send' 
                              ? (l10n.sendRequest) 
                              : (l10n.receiveRequest),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (order['orderCategory'] != null) ...[
                      _OrderDetailRow(
                        icon: Icons.label,
                        iconColor: AppTheme.warningColor,
                        label: l10n.category,
                        child: Text(
                          order['orderCategory'].toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (order['vehicleType'] != null) ...[
                      _OrderDetailRow(
                        icon: Icons.directions_car,
                        iconColor: Colors.teal,
                        label: l10n.vehicle,
                        child: Text(
                          _getVehicleTypeText(order['vehicleType'].toString(), l10n),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (order['deliveryType'] != null) ...[
                      _OrderDetailRow(
                        icon: Icons.local_shipping,
                        iconColor: Colors.indigo,
                        label: l10n.deliveryType,
                        child: Text(
                          order['deliveryType'] == 'internal'
                              ? l10n.internalDelivery
                              : l10n.externalDelivery,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (order['senderName'] != null) ...[
                      _OrderDetailRow(
                        icon: Icons.person,
                        iconColor: Colors.brown,
                        label: l10n.senderName,
                        child: Text(
                          order['senderName'].toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (order['phone'] != null || order['senderPhoneNumber'] != null) ...[
                      _OrderDetailRow(
                        icon: Icons.phone,
                        iconColor: Colors.blueGrey,
                        label: l10n.phone,
                        child: Text(
                          order['phone']?.toString() ?? 
                          order['senderPhoneNumber']?.toString() ?? 
                          '--',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (order['distance'] != null) ...[
                      _OrderDetailRow(
                        icon: Icons.straighten,
                        iconColor: Colors.deepPurple,
                        label: l10n.distance,
                        child: Text(
                          l10n.kilometers(order['distance'].toString()),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (order['estimatedTime'] != null) ...[
                      _OrderDetailRow(
                        icon: Icons.access_time,
                        iconColor: Colors.amber,
                        label: l10n.estimatedTime,
                        child: Text(
                          l10n.minutes(order['estimatedTime'].toString()),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (order['deliveryNotes'] != null && order['deliveryNotes'].toString().isNotEmpty) ...[
                      _OrderDetailRow(
                        icon: Icons.note,
                        iconColor: Colors.grey,
                        label: l10n.notes,
                        child: Text(
                          order['deliveryNotes'].toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
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
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningColor;
      case 'accepted':
        return AppTheme.primaryColor;
      case 'on_the_way':
        return Colors.blue.shade600;
      case 'delivered':
        return AppTheme.successColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
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
}

class _OrderDetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;

  const _OrderDetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      });
      return;
    }

    final latValue = widget.location!['lat'];
    final lngValue = widget.location!['lng'];
    
    if (latValue == null || lngValue == null) {
      setState(() {
        _displayText = l10n.unknownLocation;
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
        });
      }
    } catch (e) {
      // Keep coordinates as fallback
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
      // Use OSM geocoding service for language-aware location names
      final locationName = await OSMGeocodingService.reverseGeocode(
        lat: latitude,
        lng: longitude,
        context: context,
      );
      
      if (locationName != null && locationName.isNotEmpty) {
        // Cache the result
        cache[cacheKey] = locationName;
        return locationName;
      } else {
        // Fallback to coordinates if no location name found
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
