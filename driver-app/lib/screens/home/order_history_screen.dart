import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../view_models/order_view_model.dart';
import '../../widgets/empty_state.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<OrderViewModel>(
      builder: (context, orderViewModel, _) {
        final orders = orderViewModel.myOrders;

        if (orders.isEmpty) {
          return EmptyState(
            icon: Icons.history,
            title: l10n.noOrderHistory,
            message: l10n.orderHistoryMessage,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final orderId = _getOrderId(order);
            final displayId = orderId != null && orderId.length > 8
                ? orderId.substring(0, 8)
                : orderId ?? 'N/A';
            final status = (order['status'] ?? '').toString().toLowerCase();
            final isDelivered = status == 'delivered';
            final isCancelled = status == 'cancelled';
            final formattedDate = _formatDate(order['createdAt']);
            
            final statusColor = isDelivered
                ? AppTheme.successColor
                : isCancelled
                    ? AppTheme.errorColor
                    : AppTheme.warningColor;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ModernCardShadow.medium,
                border: Border.all(
                  color: statusColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Status Icon, Order ID, Date
                        Row(
                          children: [
                            // Status Icon with gradient
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    statusColor.withOpacity(0.2),
                                    statusColor.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isDelivered
                                    ? Icons.check_circle_rounded
                                    : isCancelled
                                        ? Icons.cancel_rounded
                                        : Icons.pending_rounded,
                                color: statusColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Order ID and Status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#$displayId',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      (order['status'] ?? l10n.nA).toString().toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Date
                            if (formattedDate != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Type and Category in same row
                        Row(
                          children: [
                            // Type
                            if (order['type'] != null)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.category_rounded,
                                        size: 16,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.type,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              l10n.translateOrderType(order['type'].toString()),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textPrimary,
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
                              ),
                            if (order['type'] != null && order['orderCategory'] != null)
                              const SizedBox(width: 12),
                            // Category
                            if (order['orderCategory'] != null)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_rounded,
                                        size: 16,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.category,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              order['orderCategory'].toString(),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Price - Full width at bottom
                        if (order['price'] != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.price,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  l10n.nis(order['price'].toString()),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _getOrderId(Map<String, dynamic> order) {
    final id = order['_id'];
    if (id is String) return id;
    if (id is Map<String, dynamic>) {
      return id['_id'] ?? id['\$oid'] ?? id['oid'];
    }
    return id?.toString();
  }

  String? _formatDate(dynamic value) {
    if (value == null) return null;
    
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

    if (dateTime == null) return null;

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

