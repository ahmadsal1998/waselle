import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import 'order_details_screen.dart';

class ActiveOrderScreen extends StatelessWidget {
  const ActiveOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final activeOrder = orderProvider.activeOrder;

        if (activeOrder == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No active order',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final formattedDate = _formatDate(activeOrder['createdAt']);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Order',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        label: 'Status',
                        value: (activeOrder['status'] ?? 'N/A').toString(),
                      ),
                      _InfoChip(
                        label: 'Type',
                        value: (activeOrder['type'] ?? 'N/A').toString(),
                      ),
                      _InfoChip(
                        label: 'Category',
                        value:
                            (activeOrder['orderCategory'] ?? 'N/A').toString(),
                      ),
                      _InfoChip(
                        label: 'Vehicle',
                        value: (activeOrder['vehicleType'] ?? 'N/A').toString(),
                      ),
                      if (activeOrder['price'] != null)
                        _InfoChip(
                          label: 'Price',
                          value: '${activeOrder['price']} NIS',
                        ),
                      if (activeOrder['estimatedPrice'] != null)
                        _InfoChip(
                          label: 'Estimated',
                          value: '${activeOrder['estimatedPrice']} NIS',
                        ),
                      if (formattedDate != null)
                        _InfoChip(
                          label: 'Created',
                          value: formattedDate,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoSection(
                    title: 'Sender',
                    rows: [
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Name',
                        value: activeOrder['senderName'],
                      ),
                      _InfoRow(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: activeOrder['senderPhoneNumber'],
                      ),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: activeOrder['senderAddress'],
                      ),
                    ],
                  ),
                  if ((activeOrder['deliveryNotes'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _InfoSection(
                        title: 'Notes',
                        rows: [
                          _InfoRow(
                            icon: Icons.sticky_note_2_outlined,
                            label: null,
                            value: activeOrder['deliveryNotes'],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailsScreen(
                              orderId: activeOrder['_id'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                      ),
                      icon: const Icon(Icons.map),
                      label: const Text(
                        'Open Live Map',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _InfoSection({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...rows.where((row) => row.value != null && row.value.toString().isNotEmpty),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String? label;
  final dynamic value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                Text(
                  value.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
    );
  }
}

String? _formatDate(dynamic value) {
  DateTime? dateTime;

  if (value is String) {
    dateTime = DateTime.tryParse(value);
  } else if (value is DateTime) {
    dateTime = value;
  } else if (value is Map && value.containsKey('\$date')) {
    final rawDate = value['\$date'];
    if (rawDate is Map && rawDate.containsKey('\$numberLong')) {
      final millis = int.tryParse(rawDate['\$numberLong'].toString());
      if (millis != null) {
        dateTime =
            DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
      }
    } else if (rawDate is String) {
      dateTime = DateTime.tryParse(rawDate);
    }
  }

  if (dateTime == null) {
    return null;
  }

  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}
