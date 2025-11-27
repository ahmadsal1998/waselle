import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/order_view_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_button.dart';
import 'order_details_screen.dart';

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
      debugPrint('AvailableOrdersScreen: Received $ordersCount orders');
      
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

  String _getSafeString(dynamic value, String fallback) {
    if (value == null) return fallback;
    final str = value.toString().trim();
    return str.isEmpty ? fallback : str;
  }

  String _translateOrderType(AppLocalizations l10n, String rawType) {
    final normalizedType = rawType.toLowerCase().trim();
    if (normalizedType == 'send' || normalizedType.contains('send')) {
      return l10n.orderTypeSend;
    } else if (normalizedType == 'receive' || normalizedType.contains('receive') || normalizedType.contains('pick')) {
      return l10n.orderTypeReceive;
    }
    return rawType;
  }


  Future<void> _acceptOrder(String orderId) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Find the order to get its estimated price
    final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
    final order = orderViewModel.availableOrders.firstWhere(
      (o) => _normalizeOrderId(o['_id']) == orderId,
      orElse: () => <String, dynamic>{},
    );
    
    final estimatedPrice = order['estimatedPrice']?.toString() ?? order['price']?.toString() ?? '0';
    
    // Show price input dialog
    final finalPrice = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PriceInputDialog(
        estimatedPrice: double.tryParse(estimatedPrice) ?? 0,
        l10n: l10n,
      ),
    );
    
    if (finalPrice == null) {
      // User cancelled the dialog
      return;
    }
    
    // Accept the order first
    final success = await orderViewModel.acceptOrder(orderId);

    if (!mounted) return;

    if (success) {
      // Now propose the final price
      final priceSuccess = await orderViewModel.proposePrice(
        orderId: orderId,
        finalPrice: finalPrice,
      );
      
      if (!mounted) return;
      
      if (priceSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.orderAcceptedSuccessfully)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.orderAcceptedPricePending)),
        );
      }
      
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

  void _showOrderNotes(BuildContext context, AppLocalizations l10n, String notes) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return _OrderNotesDialog(notes: notes, l10n: l10n);
      },
    );
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
                  vertical: 16,
                ),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final normalizedId = _normalizeOrderId(order['_id']);

                  final displayId = normalizedId == null
                      ? null
                      : (normalizedId.length <= 8
                          ? normalizedId
                          : normalizedId.substring(0, 8));

                  // Get order type
                  final rawOrderType = _getSafeString(order['type'], l10n.nA);
                  final orderType = rawOrderType != l10n.nA 
                      ? _translateOrderType(l10n, rawOrderType)
                      : l10n.nA;
                  
                  // Get order category
                  final orderCategory = _getSafeString(order['orderCategory'], l10n.nA);
                  
                  // Format user address: City - Village/Area - Street
                  final senderCity = _getSafeString(order['senderCity'], '');
                  final senderVillage = _getSafeString(order['senderVillage'], '');
                  final senderStreetDetails = _getSafeString(order['senderStreetDetails'], '');
                  
                  String userAddress = '-';
                  if (senderCity.isNotEmpty || senderVillage.isNotEmpty || senderStreetDetails.isNotEmpty) {
                    final addressParts = <String>[];
                    if (senderCity.isNotEmpty) addressParts.add(senderCity);
                    if (senderVillage.isNotEmpty) addressParts.add(senderVillage);
                    if (senderStreetDetails.isNotEmpty) addressParts.add(senderStreetDetails);
                    userAddress = addressParts.join(' - ');
                  }
                  
                  // Determine pickup and delivery based on order type
                  final isSend = rawOrderType.toLowerCase() == 'send';
                  final pickupAddress = isSend ? userAddress : '-';
                  final deliveryAddress = isSend ? '-' : userAddress;
                  
                  // Get price
                  final price = order['price']?.toString() ?? '0';
                  
                  // Get notes
                  final notes = order['deliveryNotes']?.toString().trim() ?? '';

                  return _buildCleanOrderCard(
                    context: context,
                    l10n: l10n,
                    order: order,
                    displayId: displayId,
                    orderType: orderType,
                    orderCategory: orderCategory,
                    pickupAddress: pickupAddress,
                    deliveryAddress: deliveryAddress,
                    price: price,
                    notes: notes,
                    normalizedId: normalizedId,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCleanOrderCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required Map<String, dynamic> order,
    String? displayId,
    required String orderType,
    required String orderCategory,
    required String pickupAddress,
    required String deliveryAddress,
    required String price,
    required String notes,
    String? normalizedId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Order Number | Category | Price
              Row(
                children: [
                  // Order Number
                  if (displayId != null)
                    Expanded(
                      child: Text(
                        '#$displayId',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  
                  // Category
                  if (orderCategory != l10n.nA)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_bag_rounded,
                              size: 12,
                              color: Colors.purple[700],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                orderCategory,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Price
                  Expanded(
                    child: Text(
                      l10n.nis(price),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Single Row: Order Type | Pickup | Delivery
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.type,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            orderType,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Divider
                    Container(
                      width: 1,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: Colors.grey[300],
                    ),
                    
                    // Pickup Point
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Colors.red[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.pickup,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pickupAddress,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Divider
                    Container(
                      width: 1,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: Colors.grey[300],
                    ),
                    
                    // Delivery Point
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.flag_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.dropoff,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            deliveryAddress,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
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
              
              const SizedBox(height: 16),
              
              // Action Buttons Row
              Row(
                children: [
                  // Order Contents Button (for notes)
                  if (notes.isNotEmpty) ...[
                    Expanded(
                      child: ResponsiveButton.outlined(
                        context: context,
                        onPressed: () => _showOrderNotes(context, l10n, notes),
                        icon: Icons.note_rounded,
                        foregroundColor: AppTheme.textPrimary,
                        borderColor: Colors.grey[300]!,
                        borderRadius: 10,
                        child: Text(
                          l10n.orderContents,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Accept Button
                  Expanded(
                    child: ResponsiveButton.elevated(
                      context: context,
                      onPressed: normalizedId != null
                          ? () => _acceptOrder(normalizedId)
                          : null,
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      borderRadius: 10,
                      child: Text(
                        l10n.accept,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderNotesDialog extends StatefulWidget {
  final String notes;
  final AppLocalizations l10n;

  const _OrderNotesDialog({
    required this.notes,
    required this.l10n,
  });

  @override
  State<_OrderNotesDialog> createState() => _OrderNotesDialogState();
}

class _OrderNotesDialogState extends State<_OrderNotesDialog> {
  final ScrollController _scrollController = ScrollController();
  bool _showTopFade = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentScroll = _scrollController.position.pixels;
    
    setState(() {
      _showTopFade = currentScroll > 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern Header with Gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.note_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.l10n.orderContents,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey[700],
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable Content Area with Fade Indicators
            Flexible(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 4,
                      radius: const Radius.circular(2),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            widget.notes,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                              height: 1.7,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Top Fade Indicator
                  if (_showTopFade)
                    Positioned(
                      top: 24,
                      left: 24,
                      right: 24,
                      height: 20,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Modern Close Button
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child:                 ResponsiveButton.elevated(
                  context: context,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icons.check_rounded,
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  borderRadius: 14,
                  child: Text(
                    widget.l10n.close,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for entering the final delivery price
class _PriceInputDialog extends StatefulWidget {
  final double estimatedPrice;
  final AppLocalizations l10n;

  const _PriceInputDialog({
    required this.estimatedPrice,
    required this.l10n,
  });

  @override
  State<_PriceInputDialog> createState() => _PriceInputDialogState();
}

class _PriceInputDialogState extends State<_PriceInputDialog> {
  late TextEditingController _priceController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.estimatedPrice.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);
    
    if (price == null || price <= 0) {
      setState(() {
        _errorText = widget.l10n.enterValidPrice;
      });
      return;
    }
    
    Navigator.of(context).pop(price);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.attach_money_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.l10n.setDeliveryPrice,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estimated price info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${widget.l10n.estimatedPrice}: ${widget.l10n.nis(widget.estimatedPrice.toStringAsFixed(0))}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Price input field
                  Text(
                    widget.l10n.enterFinalPrice,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: widget.l10n.nisSymbol,
                      suffixStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                      errorText: _errorText,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      if (_errorText != null) {
                        setState(() {
                          _errorText = null;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    widget.l10n.priceWillBeSentToCustomer,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Action buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: ResponsiveButton.outlined(
                      context: context,
                      onPressed: () => Navigator.of(context).pop(),
                      foregroundColor: AppTheme.textPrimary,
                      borderColor: Colors.grey[300]!,
                      borderRadius: 12,
                      child: Text(
                        widget.l10n.cancel,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ResponsiveButton.elevated(
                      context: context,
                      onPressed: _validateAndSubmit,
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      borderRadius: 12,
                      child: Text(
                        widget.l10n.confirmPrice,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
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