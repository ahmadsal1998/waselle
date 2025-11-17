import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/order_view_model.dart';
import '../../widgets/empty_state.dart';
import '../../utils/address_formatter.dart';
import 'order_details_screen.dart';
import 'order_map_details_screen.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshOrders();
    });
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderViewModel =
          Provider.of<OrderViewModel>(context, listen: false);
      
      // Check if driver is available before fetching
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (!authViewModel.isAvailable) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please enable availability to see orders';
        });
        return;
      }
      
      debugPrint('AvailableOrdersScreen: Fetching orders...');
      await orderViewModel.fetchAvailableOrders();
      
      final ordersCount = orderViewModel.availableOrders.length;
      debugPrint('AvailableOrdersScreen: Received ${ordersCount} orders');
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('AvailableOrdersScreen: Error: $e');
      debugPrint('AvailableOrdersScreen: Stack trace: $stackTrace');
      
      setState(() {
        _isLoading = false;
        final errorString = e.toString();
        if (errorString.contains('401')) {
          _errorMessage = 'Authentication required. Please log in again.';
        } else if (errorString.contains('403')) {
          _errorMessage = 'Driver must be available and have location set';
        } else if (errorString.contains('400')) {
          _errorMessage = 'Please ensure your vehicle type and location are set';
        } else {
          _errorMessage = 'Failed to load orders: ${e.toString()}';
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'An error occurred'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String? _normalizeOrderId(dynamic rawId) {
    if (rawId == null) return null;
    if (rawId is String && rawId.trim().isNotEmpty) {
      return rawId.trim();
    }
    if (rawId is Map<String, dynamic>) {
      final nestedId = rawId['_id'] ?? rawId['\$oid'] ?? rawId['oid'];
      if (nestedId is String && nestedId.trim().isNotEmpty) {
        return nestedId.trim();
      }
    }
    final asString = rawId.toString().trim();
    return asString.isNotEmpty ? asString : null;
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
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
        return Colors.grey;
    }
  }

  /// Get color for order type (internal = blue, external = green)
  Color _getOrderTypeColor(String? orderType) {
    final type = orderType?.toLowerCase() ?? '';
    if (type.contains('internal')) {
      return Colors.blue;
    } else if (type.contains('external')) {
      return Colors.green;
    }
    return Colors.grey;
  }

  /// Get color for delivery type (internal = blue, external = green)
  Color _getDeliveryTypeColor(String? deliveryType) {
    final type = deliveryType?.toLowerCase() ?? '';
    if (type.contains('internal')) {
      return Colors.blue;
    } else if (type.contains('external')) {
      return Colors.green;
    }
    return Colors.grey;
  }

  /// Get icon for order type
  IconData _getOrderTypeIcon(String? orderType) {
    final type = orderType?.toLowerCase() ?? '';
    if (type.contains('internal')) {
      return Icons.business;
    } else if (type.contains('external')) {
      return Icons.public;
    }
    return Icons.category;
  }

  /// Get icon for delivery type
  IconData _getDeliveryTypeIcon(String? deliveryType) {
    final type = deliveryType?.toLowerCase() ?? '';
    if (type.contains('internal')) {
      return Icons.home;
    } else if (type.contains('external')) {
      return Icons.location_city;
    }
    return Icons.directions;
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '';
    try {
      String dateString;
      if (dateValue is String) {
        dateString = dateValue;
      } else {
        dateString = dateValue.toString();
      }
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateValue.toString();
    }
  }

  String _getSafeString(dynamic value, String fallback) {
    if (value == null) return fallback;
    final str = value.toString().trim();
    return str.isEmpty ? fallback : str;
  }

  Future<void> _acceptOrder(String orderId) async {
    final l10n = AppLocalizations.of(context)!;
    final orderViewModel =
        Provider.of<OrderViewModel>(context, listen: false);
    final success = await orderViewModel.acceptOrder(orderId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.orderAcceptedSuccessfully)),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: orderId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToAcceptOrder)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final driverVehicleType = authViewModel.user?['vehicleType'] as String?;

    return Consumer<OrderViewModel>(
      builder: (context, orderViewModel, _) {
        // Get all available orders (already filtered by vehicle type in ViewModel)
        final orders = orderViewModel.availableOrders;
        
        debugPrint('AvailableOrdersScreen: Displaying ${orders.length} orders (driver vehicle type: $driverVehicleType)');

        if (_isLoading && orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.refresh,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (_errorMessage != null && orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ModernCardShadow.light,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _refreshOrders,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.refresh,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (orders.isEmpty) {
          return EmptyState(
            icon: Icons.inbox,
            title: l10n.noAvailableOrders,
            actionLabel: l10n.refresh,
            onActionPressed: () {
              _refreshOrders();
            },
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshOrders,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive padding based on screen width
              final isTablet = constraints.maxWidth > 600;
              final horizontalPadding = isTablet ? 24.0 : 16.0;
              
              return ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 10,
                ),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final normalizedId = _normalizeOrderId(order['_id']);
                  final distance = order['distanceFromDriver'] ?? order['distance'] ?? 0.0;

                  final displayId = normalizedId == null
                      ? null
                      : (normalizedId.length <= 8
                          ? normalizedId
                          : normalizedId.substring(0, 8));

                  // Get order data - only essential information
                  final orderType = _getSafeString(order['type'], l10n.nA);
                  final orderCategory = _getSafeString(order['orderCategory'], l10n.nA);
                  final deliveryType = _getSafeString(order['deliveryType'], l10n.nA);
                  
                  // Format pickup address: City - Village/Area - Street
                  final senderCity = _getSafeString(order['senderCity'], '');
                  final senderVillage = _getSafeString(order['senderVillage'], '');
                  final senderStreetDetails = _getSafeString(order['senderStreetDetails'], '');
                  
                  String pickupAddress = 'N/A';
                  if (senderCity.isNotEmpty || senderVillage.isNotEmpty || senderStreetDetails.isNotEmpty) {
                    final addressParts = <String>[];
                    if (senderCity.isNotEmpty) addressParts.add(senderCity);
                    if (senderVillage.isNotEmpty) addressParts.add(senderVillage);
                    if (senderStreetDetails.isNotEmpty) addressParts.add(senderStreetDetails);
                    pickupAddress = addressParts.join(' - ');
                  }
                  
                  // Format distance
                  final distanceText = distance > 0
                      ? l10n.kilometers(distance.toStringAsFixed(2))
                      : l10n.nA;

                  // Get colors and icons for type and delivery type
                  final orderTypeColor = _getOrderTypeColor(orderType);
                  final deliveryTypeColor = _getDeliveryTypeColor(deliveryType);
                  final orderTypeIcon = _getOrderTypeIcon(orderType);
                  final deliveryTypeIcon = _getDeliveryTypeIcon(deliveryType);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: orderTypeColor.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Optional: Expand card on tap for additional details
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: orderTypeColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: Order ID | Order Type | Order Category
                                Row(
                                  children: [
                                    // Order ID - Modern badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.grey[50]!,
                                            Colors.grey[100]!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.receipt_long_rounded,
                                            size: 16,
                                            color: Colors.grey[800],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            displayId != null 
                                                ? '#$displayId'
                                                : l10n.order,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey[900],
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Order Type - Modern pill badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            orderTypeColor.withOpacity(0.15),
                                            orderTypeColor.withOpacity(0.08),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            orderTypeIcon,
                                            size: 15,
                                            color: orderTypeColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            orderType.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: orderTypeColor,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    // Category - Modern pill badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.shopping_bag_rounded,
                                            size: 15,
                                            color: Colors.purple[700],
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              orderCategory,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.purple[700],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                
                                // Second Row: Pickup Address (left) | Distance (right)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Pickup Address
                                      Expanded(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.location_on_rounded,
                                                size: 18,
                                                color: Colors.red[600],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Pickup',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    pickupAddress,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[900],
                                                      fontWeight: FontWeight.w500,
                                                      height: 1.3,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Distance - Modern badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue[50]!,
                                              Colors.blue[100]!,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.blue[200]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.straighten_rounded,
                                              size: 16,
                                              color: Colors.blue[700],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              distanceText,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.blue[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                
                                // Accept Order Button - Full-width at bottom
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green[600]!,
                                        Colors.green[700]!,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: normalizedId == null
                                          ? null
                                          : () => _acceptOrder(normalizedId),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              size: 22,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              l10n.accept,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

}
