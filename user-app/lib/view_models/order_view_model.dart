import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_category.dart';
import '../repositories/api_service.dart';
import '../services/socket_service.dart';

class OrderViewModel with ChangeNotifier {
  OrderViewModel() {
    _setupSocketListeners();
  }

  final Map<String, Map<String, dynamic>> _activeOrders = {};
  final Set<String> _trackedStatuses = {'pending', 'accepted', 'on_the_way'};

  List<Map<String, dynamic>> _orders = [];
  String? _selectedActiveOrderId;

  List<OrderCategory> _orderCategories = [];
  bool _orderCategoriesLoaded = false;
  bool _isLoadingOrderCategories = false;
  String? _orderCategoriesError;

  List<Map<String, dynamic>> get orders => _orders;

  List<Map<String, dynamic>> get activeOrders {
    final ordered = _orders
        .where((order) {
          final orderId = order['_id']?.toString();
          return orderId != null && _activeOrders.containsKey(orderId);
        })
        .map((order) {
          final orderId = order['_id']?.toString();
          return _activeOrders[orderId] ?? Map<String, dynamic>.from(order);
        })
        .toList();
    final orderedIds = ordered
        .map((order) => order['_id']?.toString())
        .whereType<String>()
        .toSet();
    final remaining = _activeOrders.entries
        .where((entry) => !orderedIds.contains(entry.key))
        .map((entry) => entry.value)
        .toList();
    return [...ordered, ...remaining];
  }

  Map<String, dynamic>? get activeOrder {
    if (_selectedActiveOrderId != null) {
      return _activeOrders[_selectedActiveOrderId];
    }
    final list = activeOrders;
    return list.isNotEmpty ? list.first : null;
  }

  List<OrderCategory> get orderCategories => _orderCategories;
  bool get isLoadingOrderCategories => _isLoadingOrderCategories;
  String? get orderCategoriesError => _orderCategoriesError;

  void _setupSocketListeners() {
    SocketService.off('order-accepted');
    SocketService.on('order-accepted', (data) {
      final order = _normalizeOrder(data);
      if (order == null) return;
      _applyIncomingOrder(order);
    });

    SocketService.off('order-updated');
    SocketService.on('order-updated', (data) {
      final order = _normalizeOrder(data);
      if (order == null) return;
      _applyIncomingOrder(order);
    });
  }

  void _applyIncomingOrder(Map<String, dynamic> order) {
    _updateOrderInList(order);
    _syncActiveOrders(order);
    notifyListeners();
  }

  void _syncActiveOrders([Map<String, dynamic>? candidate]) {
    if (candidate != null) {
      final orderId = candidate['_id']?.toString();
      if (orderId != null) {
        if (_isTrackedStatus(candidate['status'])) {
          _activeOrders[orderId] = candidate;
          _selectedActiveOrderId ??= orderId;
        } else {
          if (_activeOrders.remove(orderId) != null &&
              _selectedActiveOrderId == orderId) {
            _selectedActiveOrderId =
                _activeOrders.isNotEmpty ? _activeOrders.keys.first : null;
          }
        }
      }
    } else {
      _activeOrders.clear();
      for (final order in _orders) {
        final orderId = order['_id']?.toString();
        if (orderId == null) continue;
        if (_isTrackedStatus(order['status'])) {
          _activeOrders[orderId] = order;
        }
      }
      if (_selectedActiveOrderId != null &&
          !_activeOrders.containsKey(_selectedActiveOrderId)) {
        _selectedActiveOrderId =
            _activeOrders.isNotEmpty ? _activeOrders.keys.first : null;
      }
      _selectedActiveOrderId ??=
          _activeOrders.isNotEmpty ? _activeOrders.keys.first : null;
    }
  }

  Map<String, dynamic>? _normalizeOrder(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(
        raw.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }

  Future<void> loadOrderCategories({bool forceRefresh = false}) async {
    if (_isLoadingOrderCategories) return;
    if (!forceRefresh && _orderCategoriesLoaded) return;

    _isLoadingOrderCategories = true;
    notifyListeners();

    try {
      final response = await ApiService.getOrderCategories(activeOnly: true);
      _orderCategories = response
          .map((item) => OrderCategory.fromJson(item))
          .where((category) => category.isActive && category.name.isNotEmpty)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _orderCategoriesError = null;
      _orderCategoriesLoaded = true;
    } catch (e) {
      _orderCategories = [];
      _orderCategoriesError = e.toString();
    } finally {
      _isLoadingOrderCategories = false;
      notifyListeners();
    }
  }

  OrderCategory? categoryById(String id) {
    try {
      return _orderCategories.firstWhere((category) => category.id == id);
    } catch (_) {
      return null;
    }
  }

  void _updateOrderInList(Map<String, dynamic> updatedOrder) {
    final index = _orders.indexWhere(
      (order) => order['_id'] == updatedOrder['_id'],
    );
    if (index != -1) {
      _orders[index] = updatedOrder;
    } else {
      _orders.insert(0, updatedOrder);
    }
  }

  Future<void> fetchOrders() async {
    try {
      // Check if authenticated before fetching orders
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        // Not authenticated, don't fetch orders
        return;
      }
      
      final response = await ApiService.getOrders();
      if (response['orders'] != null) {
        _orders = List<Map<String, dynamic>>.from(response['orders']);
        _syncActiveOrders();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
  }

  Future<bool> createOrder({
    required String type,
    required String deliveryType,
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropoffLocation,
    required String vehicleType,
    required String orderCategory,
    required String senderName,
    required String senderCity,
    required String senderVillage,
    required String senderStreetDetails,
    required int senderPhoneNumber,
    String? deliveryNotes,
    double? estimatedPrice,
  }) async {
    try {
      final response = await ApiService.createOrder(
        type: type,
        deliveryType: deliveryType,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        vehicleType: vehicleType,
        orderCategory: orderCategory,
        senderName: senderName,
        senderCity: senderCity,
        senderVillage: senderVillage,
        senderStreetDetails: senderStreetDetails,
        senderPhoneNumber: senderPhoneNumber,
        deliveryNotes: deliveryNotes,
        estimatedPrice: estimatedPrice,
      );

      if (response['order'] != null) {
        final createdOrder =
            Map<String, dynamic>.from(response['order'] as Map<String, dynamic>);
        _updateOrderInList(createdOrder);
        _syncActiveOrders(createdOrder);
        await fetchOrders();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return false;
    }
  }

  Future<double?> estimateOrderCost({
    required String vehicleType,
    Map<String, dynamic>? pickupLocation,
    Map<String, dynamic>? dropoffLocation,
  }) async {
    try {
      // Estimate endpoint is now public, no auth check needed
      final response = await ApiService.estimateOrderCost(
        vehicleType: vehicleType,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
      );
      if (response['estimatedPrice'] != null) {
        final price = response['estimatedPrice'];
        if (price is num) {
          return price.toDouble();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error estimating order cost: $e');
      return null;
    }
  }

  Map<String, dynamic>? getActiveOrderById(String orderId) =>
      _activeOrders[orderId];

  void selectActiveOrder(String? orderId) {
    if (orderId == null) {
      _selectedActiveOrderId =
          _activeOrders.isNotEmpty ? _activeOrders.keys.first : null;
    } else if (_activeOrders.containsKey(orderId)) {
      _selectedActiveOrderId = orderId;
    }
    notifyListeners();
  }

  void setActiveOrder(Map<String, dynamic>? order) {
    if (order == null) {
      _selectedActiveOrderId = null;
      notifyListeners();
      return;
    }
    final normalized = _normalizeOrder(order);
    if (normalized == null) return;

    final orderId = normalized['_id']?.toString();
    if (orderId == null) return;
    _updateOrderInList(normalized);
    _syncActiveOrders(normalized);
    _selectedActiveOrderId = orderId;
    notifyListeners();
  }

  bool _isTrackedStatus(dynamic status) {
    if (status == null) return false;
    final normalized = status.toString().trim().toLowerCase();
    return _trackedStatuses.contains(normalized);
  }
}
