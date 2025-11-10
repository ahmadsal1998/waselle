import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final orders = orderProvider.myOrders;

        if (orders.isEmpty) {
          return const Center(
            child: Text(
              'No order history',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(
                  order['status'] == 'delivered'
                      ? Icons.check_circle
                      : Icons.pending,
                  color: order['status'] == 'delivered'
                      ? Colors.green
                      : Colors.orange,
                  size: 40,
                ),
                title: Text(
                  'Order #${order['_id'].toString().substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Status: ${order['status']}'),
                    Text('Price: \$${order['price']}'),
                    Text('Type: ${order['type']}'),
                  ],
                ),
                trailing: Text(
                  order['createdAt'] != null
                      ? _formatDate(order['createdAt'])
                      : '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
