import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/order_repository.dart';
import '../services/socket_service.dart';

class OrderViewModel with ChangeNotifier {
  OrderViewModel({OrderRepository? orderRepository})
      : _orderRepository = orderRepository ?? OrderRepository() {
    _loadDriverVehicleType();
    // Setup listeners will be called after socket initialization
  }

  final OrderRepository _orderRepository;

  List<Map<String, dynamic>> _availableOrders = [];
  List<Map<String, dynamic>> _myOrders = [];
  Map<String, dynamic>? _activeOrder;
  String? _driverVehicleType;
  bool _isFetchingAvailable = false;
  bool _listenersSetup = false;

  List<Map<String, dynamic>> get availableOrders => _availableOrders;
  List<Map<String, dynamic>> get myOrders => _myOrders;
  Map<String, dynamic>? get activeOrder => _activeOrder;
  List<Map<String, dynamic>> get activeOrders => _myOrders
      .where((order) => ['accepted', 'on_the_way'].contains(order['status']))
      .toList();
  String? get driverVehicleType => _driverVehicleType;

  /// Setup socket listeners. Should be called after socket initialization.
  void setupSocketListeners() {
    debugPrint('OrderViewModel: Setting up socket listeners');
    
    // Always remove old listeners first to avoid duplicates
    SocketService.off('new-order');
    SocketService.off('order-removed');
    SocketService.off('order-updated');
    SocketService.off('connect');
    
    _setupSocketListeners();
    _listenersSetup = true;
    
    debugPrint('OrderViewModel: Socket listeners setup complete');
  }

  void _setupSocketListeners() {
    SocketService.off('new-order');
    SocketService.on('new-order', (data) async {
      debugPrint('Received new-order event via socket');
      if (data is Map<String, dynamic>) {
        final order = Map<String, dynamic>.from(data);
        debugPrint('New order received: ${order['_id']}, vehicleType: ${order['vehicleType']}');
        if (_shouldIncludeOrder(order)) {
          debugPrint('Order matches driver vehicle type, adding to list');
          _insertOrUpdateAvailable(order);
          notifyListeners();
          await _refreshAvailableOrdersFromServer();
        } else {
          debugPrint('Order does not match driver vehicle type, ignoring');
        }
      } else {
        debugPrint('Received new-order event but data is not a map, refreshing from server');
        await _refreshAvailableOrdersFromServer();
      }
    });

    SocketService.off('order-removed');
    SocketService.on('order-removed', (data) async {
      if (data is Map<String, dynamic>) {
        final payload = Map<String, dynamic>.from(data);
        final orderId = payload['orderId'];
        if (orderId != null) {
          final orderIdStr = orderId is String ? orderId : orderId.toString();
          final beforeLength = _availableOrders.length;
          _availableOrders.removeWhere(
            (order) => _getOrderId(order) == orderIdStr,
          );
          if (_availableOrders.length != beforeLength) {
            debugPrint('OrderViewModel: Removed order from list: $orderIdStr');
            notifyListeners();
          }
        }
      }
      // Don't refresh from server immediately - the removal is already handled
      // Only refresh if we want to ensure consistency
      // await _refreshAvailableOrdersFromServer();
    });

    SocketService.off('order-updated');
    SocketService.on('order-updated', (data) {
      if (data is Map<String, dynamic>) {
        final order = Map<String, dynamic>.from(data);
        if (_activeOrder?['_id'] == order['_id']) {
          _activeOrder = order;
        }
        _updateOrderInList(order);
        notifyListeners();
      }
    });

    // Listen for price-accepted event (customer accepted the proposed price)
    SocketService.off('price-accepted');
    SocketService.on('price-accepted', (data) {
      debugPrint('💰 Received price-accepted event: $data');
      if (data is Map<String, dynamic>) {
        final order = data['order'];
        if (order is Map<String, dynamic>) {
          final orderId = _getOrderId(order);
          if (_activeOrder != null && _getOrderId(_activeOrder!) == orderId) {
            _activeOrder = Map<String, dynamic>.from(order);
          }
          _updateOrderInList(Map<String, dynamic>.from(order));
          notifyListeners();
        }
      }
    });

    // Listen for price-rejected event (customer rejected the proposed price)
    SocketService.off('price-rejected');
    SocketService.on('price-rejected', (data) {
      debugPrint('💰 Received price-rejected event: $data');
      if (data is Map<String, dynamic>) {
        final order = data['order'];
        if (order is Map<String, dynamic>) {
          final orderId = _getOrderId(order);
          if (_activeOrder != null && _getOrderId(_activeOrder!) == orderId) {
            _activeOrder = Map<String, dynamic>.from(order);
          }
          _updateOrderInList(Map<String, dynamic>.from(order));
          notifyListeners();
        }
      }
    });

    // Listen for socket connection to ensure listeners are active
    SocketService.off('connect');
    SocketService.on('connect', (_) {
      debugPrint('OrderViewModel: Socket connected, listeners are active');
      // Re-attach listeners when socket reconnects
      _setupSocketListeners();
      // Refresh orders when socket reconnects
      fetchAvailableOrders();
    });
  }

  Future<void> _loadDriverVehicleType() async {
    // Try to get from SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    final storedType = prefs.getString('vehicleType');
    
    String? type;
    if (storedType != null && storedType.isNotEmpty) {
      type = storedType;
    }
    
    // If not in SharedPreferences, it should be loaded from user profile
    // but we'll rely on refreshDriverVehicleType to sync it
    
    if (_driverVehicleType != type) {
      debugPrint('OrderViewModel: Setting driver vehicle type to: $type');
      _driverVehicleType = type;
      _filterCachedAvailableOrders();
    } else {
      debugPrint('OrderViewModel: Driver vehicle type already set to: $type');
    }
  }
  
  /// Load vehicle type from AuthViewModel user data
  Future<void> refreshDriverVehicleType() async {
    // This will be called with user data from AuthViewModel
    // For now, just reload from SharedPreferences
    await _loadDriverVehicleType();
    notifyListeners();
  }
  
  /// Set vehicle type directly (for use with AuthViewModel)
  void setDriverVehicleType(String? vehicleType) {
    if (_driverVehicleType != vehicleType) {
      debugPrint('OrderViewModel: Setting driver vehicle type from user profile: $vehicleType');
      _driverVehicleType = vehicleType;
      _filterCachedAvailableOrders();
      notifyListeners();
    }
  }

  Future<void> _refreshAvailableOrdersFromServer() async {
    await fetchAvailableOrders();
  }
  
  String? _getOrderId(Map<String, dynamic> order) {
    final id = order['_id'];
    if (id is String) return id;
    if (id is Map<String, dynamic>) {
      return id['_id'] ?? id['\$oid'] ?? id['oid'];
    }
    return id?.toString();
  }

  void _insertOrUpdateAvailable(Map<String, dynamic> order) {
    final orderId = _getOrderId(order);
    if (orderId == null) return;
    
    final index = _availableOrders.indexWhere(
      (existing) => _getOrderId(existing) == orderId,
    );
    if (index == -1) {
      // Only add if order is still pending (hasn't been accepted)
      final status = order['status'];
      if (status == null || status == 'pending') {
        _availableOrders.insert(0, Map<String, dynamic>.from(order));
        debugPrint('OrderViewModel: Added new order to list: $orderId');
      }
    } else {
      // Update existing order
      _availableOrders[index] = Map<String, dynamic>.from(order);
      debugPrint('OrderViewModel: Updated existing order in list: $orderId');
    }
  }

  bool _shouldIncludeOrder(Map<String, dynamic> order) {
    // If driver doesn't have a vehicle type set, include all orders
    if (_driverVehicleType == null) {
      debugPrint('OrderViewModel: Driver has no vehicle type, including order: ${_getOrderId(order)}');
      return true;
    }
    final vehicleType = order['vehicleType'];
    final shouldInclude = vehicleType is String && vehicleType == _driverVehicleType;
    if (!shouldInclude) {
      debugPrint('OrderViewModel: Order vehicle type ($vehicleType) does not match driver type ($_driverVehicleType)');
    }
    return shouldInclude;
  }

  void _filterCachedAvailableOrders() {
    if (_driverVehicleType == null) {
      return;
    }
    _availableOrders = _availableOrders
        .where((order) => _shouldIncludeOrder(order))
        .toList();
  }

  void _updateOrderInList(Map<String, dynamic> updatedOrder) {
    final orderId = _getOrderId(updatedOrder);
    if (orderId == null) return;
    
    final status = updatedOrder['status'];
    final shouldInclude = _shouldIncludeOrder(updatedOrder);
    
    // Remove from available orders if status is no longer pending
    if (status != null && status != 'pending') {
      _availableOrders.removeWhere(
        (order) => _getOrderId(order) == orderId,
      );
    } else {
      // Update or add to available orders if still pending
      final index = _availableOrders.indexWhere(
        (order) => _getOrderId(order) == orderId,
      );
      if (index != -1 && shouldInclude) {
        _availableOrders[index] = Map<String, dynamic>.from(updatedOrder);
      } else if (index != -1 && !shouldInclude) {
        _availableOrders.removeAt(index);
      } else if (index == -1 && shouldInclude) {
        _availableOrders.insert(0, Map<String, dynamic>.from(updatedOrder));
      }
    }

    // Update my orders
    final myIndex = _myOrders.indexWhere(
      (order) => _getOrderId(order) == orderId,
    );
    if (myIndex != -1) {
      _myOrders[myIndex] = Map<String, dynamic>.from(updatedOrder);
    }
  }

  Future<void> fetchAvailableOrders() async {
    if (_isFetchingAvailable) {
      debugPrint('OrderViewModel: Already fetching orders, skipping...');
      return;
    }
    _isFetchingAvailable = true;
    try {
      debugPrint('OrderViewModel: Fetching available orders...');
      debugPrint('OrderViewModel: Driver vehicle type: $_driverVehicleType');
      
      final response = await _orderRepository.getAvailableOrders();
      debugPrint('OrderViewModel: Received response keys: ${response.keys}');
      debugPrint('OrderViewModel: Full response: $response');
      
      if (response['orders'] != null) {
        final fetchedOrders =
            List<Map<String, dynamic>>.from(response['orders']);
        debugPrint('OrderViewModel: Fetched ${fetchedOrders.length} orders from API');
        
        if (fetchedOrders.isNotEmpty) {
          debugPrint('OrderViewModel: First order sample: ${fetchedOrders.first}');
        }
        
        // Filter by vehicle type if driver has a vehicle type
        final filteredFetchedOrders =
            fetchedOrders.where(_shouldIncludeOrder).toList();
        debugPrint('OrderViewModel: After vehicle type filter: ${filteredFetchedOrders.length} orders');
        
        // Merge fetched orders with existing ones instead of replacing
        // This preserves orders that were added via socket but might not be in the server response yet
        final Map<String, Map<String, dynamic>> ordersMap = {};
        
        // First, add all existing orders to the map
        for (final order in _availableOrders) {
          final orderId = _getOrderId(order);
          if (orderId != null) {
            ordersMap[orderId] = Map<String, dynamic>.from(order);
          }
        }
        
        // Then, update/add fetched orders (these have the latest data from server)
        for (final order in filteredFetchedOrders) {
          final orderId = _getOrderId(order);
          if (orderId != null) {
            ordersMap[orderId] = Map<String, dynamic>.from(order);
          }
        }
        
        debugPrint('OrderViewModel: Total orders in map: ${ordersMap.length}');
        
        // Convert back to list and filter out non-pending orders
        // (orders that have been accepted by other drivers)
        final pendingOrders = ordersMap.values
            .where((order) {
              final status = order['status'];
              final isPending = status == null || status == 'pending';
              if (!isPending) {
                debugPrint('OrderViewModel: Filtering out order with status: $status');
              }
              return isPending;
            })
            .toList();
        
        debugPrint('OrderViewModel: Final pending orders: ${pendingOrders.length}');
        _availableOrders = pendingOrders;
        notifyListeners();
      } else {
        debugPrint('OrderViewModel: No orders key in response');
        _availableOrders = [];
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('OrderViewModel: Error fetching available orders: $e');
      debugPrint('OrderViewModel: Stack trace: $stackTrace');
      // Re-throw the error so the UI can handle it
      rethrow;
    } finally {
      _isFetchingAvailable = false;
    }
  }

  Future<void> fetchMyOrders() async {
    try {
      final response = await _orderRepository.getOrders();
      if (response['orders'] != null) {
        _myOrders = List<Map<String, dynamic>>.from(response['orders']);
        _activeOrder = _myOrders.firstWhere(
          (order) => ['accepted', 'on_the_way'].contains(order['status']),
          orElse: () => {},
        );
        if (_activeOrder!.isEmpty) _activeOrder = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching my orders: $e');
    }
  }

  Future<bool> acceptOrder(String orderId) async {
    try {
      final response = await _orderRepository.acceptOrder(orderId);

      if (response['order'] != null) {
        _activeOrder = response['order'];
        // Remove accepted order from available orders
        _availableOrders.removeWhere(
          (order) => _getOrderId(order) == orderId,
        );
        debugPrint('OrderViewModel: Removed accepted order from available list: $orderId');
        await fetchMyOrders();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error accepting order: $e');
      return false;
    }
  }

  Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final response = await _orderRepository.updateOrderStatus(
        orderId: orderId,
        status: status,
      );

      if (response['order'] != null) {
        if (_activeOrder?['_id'] == orderId) {
          _activeOrder = response['order'];
          if (status == 'delivered') {
            _activeOrder = null;
          }
        }
        await fetchMyOrders();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  void setActiveOrder(Map<String, dynamic>? order) {
    _activeOrder = order;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> fetchOrderById(String orderId) async {
    try {
      final response = await _orderRepository.getOrderById(orderId);
      final order = response['order'];
      if (order is Map<String, dynamic>) {
        return order;
      }
    } catch (e) {
      debugPrint('Error fetching order by id: $e');
    }
    return null;
  }

  /// Propose a final price for an order
  Future<bool> proposePrice({
    required String orderId,
    required double finalPrice,
  }) async {
    try {
      final response = await _orderRepository.proposePrice(
        orderId: orderId,
        finalPrice: finalPrice,
      );

      if (response['order'] != null) {
        // Update the order in the local list
        final updatedOrder = response['order'];
        if (_activeOrder?['_id'] == orderId) {
          _activeOrder = updatedOrder;
        }
        _updateOrderInList(Map<String, dynamic>.from(updatedOrder));
        await fetchMyOrders();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error proposing price: $e');
      return false;
    }
  }
}

