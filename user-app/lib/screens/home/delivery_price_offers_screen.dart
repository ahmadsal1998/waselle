import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';
import '../../view_models/order_view_model.dart';
import '../../repositories/api_service.dart';
import '../../services/socket_service.dart';

class DeliveryPriceOffersScreen extends StatefulWidget {
  const DeliveryPriceOffersScreen({super.key});

  @override
  State<DeliveryPriceOffersScreen> createState() => _DeliveryPriceOffersScreenState();
}

class _DeliveryPriceOffersScreenState extends State<DeliveryPriceOffersScreen> {
  bool _isLoading = false;
  bool _isInitialized = false;
  List<Map<String, dynamic>> _offers = [];
  String? _error;
  bool _isWebSocketConnected = false;
  bool _isWebSocketConnecting = false;

  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getPriceOffers();
      if (mounted) {
        setState(() {
          _offers = List<Map<String, dynamic>>.from(
            response['orders'] ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Extract meaningful error message
          String errorMessage = e.toString();
          if (errorMessage.contains('Exception:')) {
            errorMessage = errorMessage.split('Exception:').last.trim();
          }
          _error = errorMessage;
          _isLoading = false;
        });
        // Log the full error for debugging
        debugPrint('Error loading price offers: $e');
      }
    }
  }

  Future<void> _respondToOffer(String orderId, bool accept) async {
    try {
      await ApiService.respondToPrice(orderId: orderId, accept: accept);
      
      if (!mounted) return;
      
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? l10n.offerAccepted : l10n.offerRejected),
          backgroundColor: accept ? Colors.green : Colors.orange,
        ),
      );
      
      // Reload offers to remove the accepted/rejected offer
      await _loadOffers();
      
      // Notify order view model to refresh orders
      if (!mounted) return;
      final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
      await orderViewModel.fetchOrders();
    } catch (e) {
      if (!mounted) return;
      
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToRespondToPrice),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setupWebSocketListener() {
    // Initialize socket if not already connected
    if (!SocketService.isConnected) {
      setState(() {
        _isWebSocketConnecting = true;
      });
      SocketService.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isWebSocketConnecting = false;
            _isWebSocketConnected = SocketService.isConnected;
          });
          // Setup listeners after connection is established
          _attachWebSocketListeners();
        }
      });
    } else {
      setState(() {
        _isWebSocketConnected = true;
      });
      _attachWebSocketListeners();
    }
  }

  void _attachWebSocketListeners() {
    // Listen for connection status changes
    SocketService.on('connect', (_) {
      if (mounted) {
        setState(() {
          _isWebSocketConnected = true;
          _isWebSocketConnecting = false;
        });
      }
    });

    SocketService.on('disconnect', (_) {
      if (mounted) {
        setState(() {
          _isWebSocketConnected = false;
        });
        // Attempt to reconnect
        _reconnectWebSocket();
      }
    });

    // Listen for new price offers
    SocketService.on('price-proposed', _handleNewPriceOffer);
  }

  void _handleNewPriceOffer(dynamic data) {
    if (!mounted) return;

    try {
      final orderId = data['orderId']?.toString();
      final newPrice = data['newPrice'] ?? data['finalPrice'];
      final status = data['status'] ?? 'new_offer';

      if (orderId == null) {
        debugPrint('Received price-proposed event without orderId');
        return;
      }

      debugPrint('💰 New price offer received: Order $orderId, Price: $newPrice');

      // Check if this order already exists in the list
      final existingIndex = _offers.indexWhere(
        (offer) => offer['_id']?.toString() == orderId,
      );

      if (existingIndex >= 0) {
        // Update existing offer
        setState(() {
          _offers[existingIndex] = {
            ..._offers[existingIndex],
            'finalPrice': newPrice,
            'priceProposedAt': DateTime.now().toIso8601String(),
            'status': status,
            // Update driver info if provided
            if (data['driverName'] != null)
              'driverId': {
                ...(_offers[existingIndex]['driverId'] as Map? ?? {}),
                'name': data['driverName'],
              },
            // Merge full order data if provided
            if (data['order'] != null) ...data['order'],
          };
        });
      } else {
        // This is a new offer - we need to fetch the full order details
        // For now, reload the offers list to get complete data
        _loadOffers();
      }

      // Show a notification to the user
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.newPriceOfferReceived),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              // Dismiss the snackbar
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('Error handling new price offer: $e');
    }
  }

  Future<void> _reconnectWebSocket() async {
    if (_isWebSocketConnecting) return;

    setState(() {
      _isWebSocketConnecting = true;
    });

    try {
      await SocketService.initialize();
      if (mounted) {
        setState(() {
          _isWebSocketConnected = SocketService.isConnected;
          _isWebSocketConnecting = false;
        });
        // Re-attach listeners after reconnection (don't re-initialize)
        if (SocketService.isConnected) {
          _attachWebSocketListeners();
        }
      }
    } catch (e) {
      debugPrint('Error reconnecting WebSocket: $e');
      if (mounted) {
        setState(() {
          _isWebSocketConnecting = false;
        });
        // Retry after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && !_isWebSocketConnected) {
            _reconnectWebSocket();
          }
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadOffers();
      _setupWebSocketListener();
    }
  }

  @override
  void dispose() {
    // Remove WebSocket listeners when screen is disposed
    SocketService.off('price-proposed');
    SocketService.off('connect');
    SocketService.off('disconnect');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
   /*   appBar: AppBar(
     //   title: Text(l10n.deliveryPriceOffers),
        elevation: 0,
        actions: [
          // WebSocket connection status indicator
          if (_isWebSocketConnecting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else if (!_isWebSocketConnected)
            Tooltip(
              message: 'Connection lost. Reconnecting...',
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(
                  Icons.wifi_off,
                  size: 20,
                  color: Colors.orange,
                ),
              ),
            )
          else
            Tooltip(
              message: 'Real-time updates active',
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(
                  Icons.wifi,
                  size: 20,
                  color: Colors.green,
                ),
              ),
            ),
        ],
      ),*/
      body: _isLoading && _offers.isEmpty
          ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              l10n.failedToLoadOffers,
                              style: const TextStyle(fontSize: 16, color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            if (_error != null && _error!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadOffers,
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n.retry),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
              : _offers.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadOffers,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          const Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              l10n.noPriceOffers,
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOffers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _offers.length,
                        itemBuilder: (context, index) {
                          final offer = _offers[index];
                          final orderId = offer['_id']?.toString() ?? '';
                          final finalPrice = offer['finalPrice']?.toDouble() ?? 0.0;
                          final estimatedPrice = offer['estimatedPrice']?.toDouble() ?? 0.0;
                          final driver = offer['driverId'];
                          final driverName = driver is Map
                              ? (driver['name'] ?? 'Unknown Driver')
                              : 'Unknown Driver';
                          final proposedAt = offer['priceProposedAt'] != null
                              ? DateTime.tryParse(offer['priceProposedAt'])
                              : null;
                          final proposedText = proposedAt != null
                              ? '${proposedAt.day}/${proposedAt.month}/${proposedAt.year} ${proposedAt.hour.toString().padLeft(2, '0')}:${proposedAt.minute.toString().padLeft(2, '0')}'
                              : '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Order ID and Date
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        l10n.orderNumber(orderId.length > 6 ? orderId.substring(0, 6) : '---'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (proposedText.isNotEmpty)
                                        Text(
                                          proposedText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Driver Name
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        driverName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Price Comparison
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              l10n.estimatedPrice,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            Text(
                                              '₪${estimatedPrice.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              l10n.proposedPrice,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '₪${finalPrice.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _respondToOffer(orderId, false),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            side: BorderSide(color: Colors.red.shade300),
                                          ),
                                          child: Text(
                                            l10n.rejectOffer,
                                            style: TextStyle(color: Colors.red.shade700),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _respondToOffer(orderId, true),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            backgroundColor: theme.colorScheme.primary,
                                          ),
                                          child: Text(
                                            l10n.acceptOffer,
                                            style: TextStyle(
                                              color: theme.colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
                    ),
    );
  }
}

