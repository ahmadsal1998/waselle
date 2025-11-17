import '../utils/api_client.dart';

class OrderRepository {
  Future<Map<String, dynamic>> getAvailableOrders() async {
    final response = await ApiClient.get('/orders/available');
    return _asMap(response);
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    final response = await ApiClient.post('/orders/$orderId/accept');
    return _asMap(response);
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final response = await ApiClient.patch(
      '/orders/$orderId/status',
      body: {'status': status},
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>> getOrders() async {
    final response = await ApiClient.get('/orders');
    return _asMap(response);
  }

  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final response = await ApiClient.get('/orders/$orderId');
    return _asMap(response);
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw const FormatException('Unexpected response format');
  }
}

