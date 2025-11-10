import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class OrderProvider with ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _activeOrder;

  List<Map<String, dynamic>> get orders => _orders;
  Map<String, dynamic>? get activeOrder => _activeOrder;

  OrderProvider() {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    SocketService.on('order-accepted', (data) {
      _activeOrder = data;
      _updateOrderInList(data);
      notifyListeners();
    });

    SocketService.on('order-updated', (data) {
      if (_activeOrder?['_id'] == data['_id'] &&
          ['pending', 'accepted', 'on_the_way'].contains(data['status'])) {
        _activeOrder = data;
      } else if (_activeOrder?['_id'] == data['_id']) {
        _activeOrder = null;
      }
      _updateOrderInList(data);
      notifyListeners();
    });
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
      final response = await ApiService.getOrders();
      if (response['orders'] != null) {
        _orders = List<Map<String, dynamic>>.from(response['orders']);
        final possibleActive = _orders.firstWhere(
          (order) =>
              ['pending', 'accepted', 'on_the_way'].contains(order['status']),
          orElse: () => <String, dynamic>{},
        );
        _activeOrder = possibleActive.isEmpty ? null : possibleActive;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
  }

  Future<bool> createOrder({
    required String type,
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropoffLocation,
    required String vehicleType,
    required String orderCategory,
    required String senderName,
    required String senderAddress,
    required String senderPhoneNumber,
    String? deliveryNotes,
    double? estimatedPrice,
  }) async {
    try {
      final response = await ApiService.createOrder(
        type: type,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        vehicleType: vehicleType,
        orderCategory: orderCategory,
        senderName: senderName,
        senderAddress: senderAddress,
        senderPhoneNumber: senderPhoneNumber,
        deliveryNotes: deliveryNotes,
        estimatedPrice: estimatedPrice,
      );

      if (response['order'] != null) {
        _activeOrder = response['order'];
        await fetchOrders();
        notifyListeners();
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

  void setActiveOrder(Map<String, dynamic>? order) {
    _activeOrder = order;
    notifyListeners();
  }
}
