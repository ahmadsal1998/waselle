import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../view_models/order_view_model.dart';
import '../../utils/address_formatter.dart';
import 'order_details_screen.dart';

class ActiveOrderScreen extends StatelessWidget {
  const ActiveOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<OrderViewModel>(
      builder: (context, orderViewModel, _) {
        final activeOrders = orderViewModel.activeOrders;

        if (activeOrders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.noActiveOrder,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accept orders from the Available tab to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: activeOrders.length,
          cacheExtent: 200,
          itemBuilder: (context, index) {
            final order = activeOrders[index];
            return _ExpandableOrderCard(
              key: ValueKey(_getOrderId(order) ?? index),
              order: order,
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
}

class _ExpandableOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;

  const _ExpandableOrderCard({
    super.key,
    required this.order,
  });

  @override
  State<_ExpandableOrderCard> createState() => _ExpandableOrderCardState();
}

class _ExpandableOrderCardState extends State<_ExpandableOrderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final order = widget.order;
    final orderId = _getOrderId(order);
    final formattedDate = _formatDate(order['createdAt']);
    final status = (order['status'] ?? '').toString().toLowerCase();
    final isOnTheWay = status == 'on_the_way';
    
    // Check if Arabic locale is active
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Get order data
    final pickup = order['pickupLocation'];
    final dropoff = order['dropoffLocation'];
    final rawOrderType = (order['type'] ?? '').toString().toLowerCase();
    final isSendOrder = rawOrderType == 'send';
    final isPickupOrder = rawOrderType == 'receive';
    
    // Format addresses - use FutureBuilder for async OSM geocoding
    return FutureBuilder<Map<String, String>>(
      future: _getOrderAddresses(order, isPickupOrder, isSendOrder, pickup, dropoff),
      builder: (context, snapshot) {
        final pickupAddress = snapshot.data?['pickup'] ?? 
            (isPickupOrder ? '-' : (pickup != null && pickup is Map<String, dynamic> 
                ? (pickup['address']?.toString().trim() ?? '-')
                : '-'));
        final dropoffAddress = snapshot.data?['dropoff'] ?? 
            (isSendOrder ? '-' : (dropoff != null && dropoff is Map<String, dynamic>
                ? (dropoff['address']?.toString().trim() ?? '-')
                : '-'));
        
        return _buildOrderCard(
          context: context,
          l10n: l10n,
          order: order,
          orderId: orderId,
          formattedDate: formattedDate,
          status: status,
          isOnTheWay: isOnTheWay,
          isArabic: isArabic,
          senderName: AddressFormatter.getCustomerName(order),
          senderPhone: _getSenderPhone(order),
          distanceText: _getDistanceText(order),
          pickupAddress: pickupAddress,
          dropoffAddress: dropoffAddress,
        );
      },
    );
  }
  
  Future<Map<String, String>> _getOrderAddresses(
    Map<String, dynamic> order,
    bool isPickupOrder,
    bool isSendOrder,
    dynamic pickup,
    dynamic dropoff,
  ) async {
    String pickupAddress = '-';
    String dropoffAddress = '-';
    
    if (isPickupOrder) {
      pickupAddress = '-';
    } else if (pickup != null && pickup is Map<String, dynamic>) {
      final storedAddress = pickup['address']?.toString().trim();
      final lat = pickup['lat'];
      final lng = pickup['lng'];
      
      if (lat != null && lng != null) {
        final latValue = lat is num ? lat.toDouble() : double.tryParse(lat.toString());
        final lngValue = lng is num ? lng.toDouble() : double.tryParse(lng.toString());
        
        if (latValue != null && lngValue != null) {
          pickupAddress = await AddressFormatter.formatPickupAddress(
            pickup,
            context: context,
          );
        } else {
          pickupAddress = storedAddress ?? '-';
        }
      } else {
        pickupAddress = storedAddress ?? '-';
      }
    }
    
    if (isSendOrder) {
      dropoffAddress = '-';
    } else {
      dropoffAddress = await AddressFormatter.formatReceiverAddress(
        order,
        context: context,
      );
    }
    
    return {
      'pickup': pickupAddress,
      'dropoff': dropoffAddress,
    };
  }
  
  String _getSenderPhone(Map<String, dynamic> order) {
    String senderPhone = order['phone']?.toString().trim() ?? '';
    if (senderPhone.isEmpty) {
      senderPhone = AddressFormatter.getCustomerPhone(order);
    }
    return senderPhone;
  }
  
  String? _getDistanceText(Map<String, dynamic> order) {
    final distance = order['distance'];
    return distance != null 
        ? 'km ${(distance is num ? distance / 1000 : double.tryParse(distance.toString()) ?? 0).toStringAsFixed(2)}'
        : null;
  }
  
  Widget _buildOrderCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required Map<String, dynamic> order,
    required String? orderId,
    required String? formattedDate,
    required String status,
    required bool isOnTheWay,
    required bool isArabic,
    required String senderName,
    required String senderPhone,
    required String? distanceText,
    required String pickupAddress,
    required String dropoffAddress,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ModernCardShadow.medium,
        border: Border.all(
          color: isOnTheWay
              ? AppTheme.warningColor.withOpacity(0.2)
              : AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // Summary section - always visible
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary header with expand/collapse button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.orderDetails,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textSecondary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Summary: First Row - Type | From | To (matches expanded view order)
                  Directionality(
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Type - First in both languages
                          Expanded(
                            child: _CompactInfoItem(
                              icon: Icons.more_vert_rounded,
                              label: l10n.type,
                              value: order['type'] != null
                                  ? _translateOrderType(l10n, order['type'].toString())
                                  : l10n.nA,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                          // From - Second in both languages
                          Expanded(
                            child: _CompactInfoItem(
                              icon: Icons.location_on_rounded,
                              label: l10n.pickup,
                              value: pickupAddress != '-' ? pickupAddress : '-',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                          // To - Third in both languages
                          Expanded(
                            child: _CompactInfoItem(
                              icon: Icons.flag_rounded,
                              label: l10n.dropoff,
                              value: dropoffAddress != '-' ? dropoffAddress : l10n.nA,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Expandable section: Full order details
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            // First Row: Created | Price | Category (Type | From | To already shown in summary)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _CompactInfoItem(
                                      icon: Icons.calendar_today_rounded,
                                      label: l10n.created,
                                      value: formattedDate != null
                                          ? formattedDate
                                          : l10n.nA,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                  ),
                                  Expanded(
                                    child: _CompactInfoItem(
                                      icon: Icons.attach_money_rounded,
                                      label: l10n.price,
                                      value: order['price'] != null
                                          ? l10n.nis(order['price'].toString())
                                          : l10n.nA,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                  ),
                                  Expanded(
                                    child: _CompactInfoItem(
                                      icon: Icons.shopping_bag_rounded,
                                      label: l10n.category,
                                      value: (order['orderCategory'] ?? l10n.nA).toString(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Sender section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 18,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.sender,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Name
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 18,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.name,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textSecondary,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              senderName != 'N/A' ? senderName : l10n.nA,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Phone
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.phone_rounded,
                                        size: 18,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.phone,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textSecondary,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              senderPhone != 'N/A' ? senderPhone : l10n.nA,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Notes section (if notes exist)
                            if ((order['deliveryNotes'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundLight,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.note_rounded,
                                          size: 18,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.notes,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      order['deliveryNotes'].toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Distance section
                            if (distanceText != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundLight,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.straighten_rounded,
                                      size: 18,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.distance,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textSecondary,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            distanceText,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            // Open Map button - always visible
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: ModernCardShadow.light,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(
                            orderId: orderId,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.map_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.openLiveMap,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

  String _translateOrderType(AppLocalizations l10n, String rawType) {
    final normalizedType = rawType.toLowerCase().trim();
    if (normalizedType == 'send' || normalizedType.contains('send')) {
      return l10n.orderTypeSend;
    } else if (normalizedType == 'receive' || normalizedType.contains('receive') || normalizedType.contains('pick')) {
      return l10n.orderTypeReceive;
    }
    return rawType;
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

    // Format: YYYY-MM-DD HH:MM (matching screenshot format)
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatSenderAddress(Map<String, dynamic> order) {
    // Try to get new format components
    final city = order['senderCity']?.toString().trim();
    final village = order['senderVillage']?.toString().trim();
    final streetDetails = order['senderStreetDetails']?.toString().trim();

    // Build address from separate components if available
    if (city != null && city.isNotEmpty ||
        village != null && village.isNotEmpty ||
        streetDetails != null && streetDetails.isNotEmpty) {
      final addressParts = <String>[];
      if (city != null && city.isNotEmpty) addressParts.add(city);
      if (village != null && village.isNotEmpty) addressParts.add(village);
      if (streetDetails != null && streetDetails.isNotEmpty) addressParts.add(streetDetails);
      if (addressParts.isNotEmpty) {
        return addressParts.join('-');
      }
    }

    // Fall back to old senderAddress format if available
    final oldAddress = order['senderAddress']?.toString().trim();
    if (oldAddress != null && oldAddress.isNotEmpty) {
      return oldAddress;
    }

    return 'N/A';
  }
}

class _CompactInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CompactInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ModernInfoSection extends StatelessWidget {
  final String title;
  final List<_ModernInfoRow> rows;

  const _ModernInfoSection({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final validRows = rows.where((row) => row.value != null && row.value.toString().isNotEmpty).toList();
    if (validRows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          ...validRows,
        ],
      ),
    );
  }
}

class _ModernInfoRow extends StatelessWidget {
  final IconData icon;
  final String? label;
  final dynamic value;

  const _ModernInfoRow({
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                if (label != null) const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ModernInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


