import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/socket_service.dart';

class OrderProvider with ChangeNotifier {
  List<Map<String, dynamic>> _availableOrders = [];
  List<Map<String, dynamic>> _myOrders = [];
  Map<String, dynamic>? _activeOrder;
  String? _driverVehicleType;
  bool _isFetchingAvailable = false;

  List<Map<String, dynamic>> get availableOrders => _availableOrders;
  List<Map<String, dynamic>> get myOrders => _myOrders;
  Map<String, dynamic>? get activeOrder => _activeOrder;
  String? get driverVehicleType => _driverVehicleType;

  OrderProvider() {
    _setupSocketListeners();
    _loadDriverVehicleType();
  }

  void _setupSocketListeners() {
    SocketService.off('new-order');
    SocketService.on('new-order', (data) async {
      if (data is Map) {
        final order = Map<String, dynamic>.from(data as Map);
        if (_shouldIncludeOrder(order)) {
          _insertOrUpdateAvailable(order);
          notifyListeners();
          await _refreshAvailableOrdersFromServer();
        }
      } else {
        await _refreshAvailableOrdersFromServer();
      }
    });

    SocketService.off('order-removed');
    SocketService.on('order-removed', (data) async {
      if (data is Map) {
        final payload = Map<String, dynamic>.from(data as Map);
        final orderId = payload['orderId'];
        if (orderId is String) {
          final beforeLength = _availableOrders.length;
          _availableOrders.removeWhere((order) => order['_id'] == orderId);
          if (_availableOrders.length != beforeLength) {
            notifyListeners();
          }
        }
      }
      await _refreshAvailableOrdersFromServer();
    });

    SocketService.off('order-updated');
    SocketService.on('order-updated', (data) {
      if (data is Map) {
        final order = Map<String, dynamic>.from(data as Map);
        if (_activeOrder?['_id'] == order['_id']) {
          _activeOrder = order;
        }
        _updateOrderInList(order);
        notifyListeners();
      }
    });
  }

  Future<void> _loadDriverVehicleType() async {
    final prefs = await SharedPreferences.getInstance();
    final storedType = prefs.getString('vehicleType');
    final type =
        storedType != null && storedType.isNotEmpty ? storedType : null;
    if (_driverVehicleType != type) {
      _driverVehicleType = type;
      _filterCachedAvailableOrders();
    }
  }

  Future<void> _refreshAvailableOrdersFromServer() async {
    await fetchAvailableOrders();
  }

  void _insertOrUpdateAvailable(Map<String, dynamic> order) {
    final index = _availableOrders.indexWhere(
      (existing) => existing['_id'] == order['_id'],
    );
    if (index == -1) {
      _availableOrders.insert(0, order);
    } else {
      _availableOrders[index] = order;
    }
  }

  bool _shouldIncludeOrder(Map<String, dynamic> order) {
    if (_driverVehicleType == null) {
      return true;
    }
    final vehicleType = order['vehicleType'];
    return vehicleType is String && vehicleType == _driverVehicleType;
  }

  void _filterCachedAvailableOrders() {
    if (_driverVehicleType == null) {
      return;
    }
    _availableOrders = _availableOrders
        .where((order) => _shouldIncludeOrder(order))
        .toList();
  }

  Future<void> refreshDriverVehicleType() async {
    await _loadDriverVehicleType();
    notifyListeners();
  }

  void _updateOrderInList(Map<String, dynamic> updatedOrder) {
    final index = _availableOrders.indexWhere(
      (order) => order['_id'] == updatedOrder['_id'],
    );
    final shouldInclude = _shouldIncludeOrder(updatedOrder);
    if (index != -1 && shouldInclude) {
      _availableOrders[index] = updatedOrder;
    } else if (index != -1 && !shouldInclude) {
      _availableOrders.removeAt(index);
    } else if (index == -1 && shouldInclude) {
      _availableOrders.insert(0, updatedOrder);
    }

    final myIndex = _myOrders.indexWhere(
      (order) => order['_id'] == updatedOrder['_id'],
    );
    if (myIndex != -1) {
      _myOrders[myIndex] = updatedOrder;
    }
  }

  Future<void> fetchAvailableOrders() async {
    if (_isFetchingAvailable) return;
    _isFetchingAvailable = true;
    try {
      final response = await ApiService.getAvailableOrders();
      if (response['orders'] != null) {
        final fetchedOrders =
            List<Map<String, dynamic>>.from(response['orders']);
        _availableOrders =
            fetchedOrders.where(_shouldIncludeOrder).toList(growable: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching available orders: $e');
    } finally {
      _isFetchingAvailable = false;
    }
  }

  Future<void> fetchMyOrders() async {
    try {
      final response = await ApiService.getOrders();
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
      final response = await ApiService.acceptOrder(orderId);

      if (response['order'] != null) {
        _activeOrder = response['order'];
        _availableOrders.removeWhere((order) => order['_id'] == orderId);
        await fetchMyOrders();
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
      final response = await ApiService.updateOrderStatus(
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
}
