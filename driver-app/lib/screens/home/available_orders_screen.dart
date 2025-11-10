import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import 'order_details_screen.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshOrders();
    });
  }

  Future<void> _refreshOrders() async {
    final orderProvider =
        Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.fetchAvailableOrders();
  }

  Future<void> _acceptOrder(String orderId) async {
    final orderProvider =
        Provider.of<OrderProvider>(context, listen: false);
    final success = await orderProvider.acceptOrder(orderId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted successfully!')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: orderId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driverVehicleType = authProvider.user?['vehicleType'] as String?;

    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final orders = driverVehicleType != null
            ? orderProvider.availableOrders
                .where(
                  (order) =>
                      order['vehicleType'] != null &&
                      order['vehicleType'] == driverVehicleType,
                )
                .toList()
            : orderProvider.availableOrders;

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No available orders',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshOrders,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshOrders,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final distance = order['distanceFromDriver'] ?? 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.local_shipping,
                      size: 40, color: Colors.blue),
                  title: Text(
                    'Order #${order['_id'].toString().substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Type: ${order['type']}'),
                      Text('Vehicle: ${order['vehicleType'] ?? 'N/A'}'),
                      Text('Price: ${order['price']} NIS'),
                      Text('Distance: ${distance.toStringAsFixed(2)} km'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _acceptOrder(order['_id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
