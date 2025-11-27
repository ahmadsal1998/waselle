import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../view_models/order_view_model.dart';
import '../../widgets/empty_state.dart';
import '../../repositories/user_repository.dart';
import '../../utils/address_formatter.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  DateTime? _selectedDate;
  bool _isTodayFilter = false;
  List<Map<String, dynamic>> _filteredOrders = [];
  double _totalDeliveryFees = 0.0;
  double? _driverBalance;
  double? _maxAllowedBalance;
  bool _isLoadingBalance = false;
  final UserRepository _userRepository = UserRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDriverBalance();
    });
  }

  Future<void> _loadDriverBalance() async {
    setState(() {
      _isLoadingBalance = true;
    });
    try {
      final response = await _userRepository.getMyBalance();
      if (mounted && response['balanceInfo'] != null) {
        final balanceInfo = response['balanceInfo'] as Map<String, dynamic>;
        setState(() {
          _driverBalance = (balanceInfo['currentBalance'] as num?)?.toDouble();
          _maxAllowedBalance = (balanceInfo['maxAllowedBalance'] as num?)?.toDouble();
          _isLoadingBalance = false;
        });
      } else {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading driver balance: $e');
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    }
  }

  /// Filter orders to show only completed (delivered) orders
  List<Map<String, dynamic>> _filterDeliveredOrders(List<Map<String, dynamic>> allOrders) {
    return allOrders.where((order) {
      final status = (order['status'] ?? '').toString().toLowerCase();
      return status == 'delivered';
    }).toList();
  }

  void _applyFilters(List<Map<String, dynamic>> orders) {
    _applyFiltersSync(orders);
  }

  void _applyFiltersSync(List<Map<String, dynamic>> orders) {
    List<Map<String, dynamic>> filtered = List.from(orders);

    if (_isTodayFilter) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      filtered = filtered.where((order) {
        final createdAt = _parseDate(order['createdAt']);
        if (createdAt == null) return false;
        return createdAt.isAfter(todayStart) && createdAt.isBefore(todayEnd);
      }).toList();
    } else if (_selectedDate != null) {
      final selectedStart = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      final selectedEnd = selectedStart.add(const Duration(days: 1));

      filtered = filtered.where((order) {
        final createdAt = _parseDate(order['createdAt']);
        if (createdAt == null) return false;
        return createdAt.isAfter(selectedStart) && createdAt.isBefore(selectedEnd);
      }).toList();
    }

    // Calculate total delivery fees
    double total = 0.0;
    for (final order in filtered) {
      final price = order['price'];
      if (price != null) {
        final priceValue = price is num ? price.toDouble() : double.tryParse(price.toString());
        if (priceValue != null) {
          total += priceValue;
        }
      }
    }

    setState(() {
      _filteredOrders = filtered;
      _totalDeliveryFees = total;
    });
  }

  DateTime? _parseDate(dynamic value) {
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
          dateTime = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
        }
      } else if (rawDate is String) {
        dateTime = DateTime.tryParse(rawDate);
      }
    }

    return dateTime;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    // Check if widget is still mounted before accessing Provider
    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _isTodayFilter = false;
      });
      // Use the widget's context, not the async context parameter
      final orderViewModel = Provider.of<OrderViewModel>(this.context, listen: false);
      final deliveredOrders = _filterDeliveredOrders(orderViewModel.myOrders);
      _applyFiltersSync(deliveredOrders);
      // Refresh balance when filter changes
      _loadDriverBalance();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _isTodayFilter = false;
    });
    // Apply filters immediately with latest orders
    final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
    final deliveredOrders = _filterDeliveredOrders(orderViewModel.myOrders);
    _applyFiltersSync(deliveredOrders);
    // Refresh balance when filters are cleared
    _loadDriverBalance();
  }

  void _showOrderDetailsModal(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailsModal(
        order: order,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<OrderViewModel>(
      builder: (context, orderViewModel, _) {
        final allOrders = orderViewModel.myOrders;
        
        // Filter to show only completed (delivered) orders
        final orders = _filterDeliveredOrders(allOrders);

        // Apply filters on initial load or when orders change
        // Only apply if filteredOrders is empty (initial load) or if orders list changed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (orders.isNotEmpty && (_filteredOrders.isEmpty || _filteredOrders.length != orders.length)) {
            _applyFilters(orders);
          } else if (orders.isEmpty) {
            // Clear filtered orders if no orders available
            setState(() {
              _filteredOrders = [];
              _totalDeliveryFees = 0.0;
            });
          }
        });

        return Column(
          children: [
            // Compact Header with Title and Filter Button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: ModernCardShadow.light,
              ),
              child: Row(
                children: [
                  Text(
                    l10n.orderHistory,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  // Filter Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showFilterBottomSheet(context, l10n, orders),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_isTodayFilter || _selectedDate != null)
                              ? AppTheme.primaryColor
                              : AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_isTodayFilter || _selectedDate != null)
                                ? AppTheme.primaryColor
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 18,
                              color: (_isTodayFilter || _selectedDate != null)
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.filter,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: (_isTodayFilter || _selectedDate != null)
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            if (_isTodayFilter || _selectedDate != null) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  '1',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Compact Statistics Row - 3 Cards
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildCompactStatCard(
                        icon: Icons.receipt_long_rounded,
                        label: l10n.totalOrders,
                        value: '${_filteredOrders.length}',
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactStatCard(
                        icon: Icons.attach_money_rounded,
                        label: l10n.totalDeliveryFees,
                        value: l10n.nis(_totalDeliveryFees.toStringAsFixed(2)),
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBalanceCard(
                        balance: _driverBalance,
                        maxAllowedBalance: _maxAllowedBalance,
                        isLoading: _isLoadingBalance,
                        onRefresh: _loadDriverBalance,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Orders List
            Expanded(
              child: _filteredOrders.isEmpty
                  ? EmptyState(
                      icon: Icons.history,
                      title: l10n.noOrderHistory,
                      message: l10n.orderHistoryMessage,
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await orderViewModel.fetchMyOrders();
                        // Filter to show only completed (delivered) orders first
                        final deliveredOrders = _filterDeliveredOrders(orderViewModel.myOrders);
                        _applyFilters(deliveredOrders);
                        // Refresh balance when pulling to refresh
                        _loadDriverBalance();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          return _buildOrderCard(context, l10n, order);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLoading = false,
    VoidCallback? onRefresh,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              if (onRefresh != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onRefresh,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: color,
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Flexible(
            child: isLoading
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard({
    required double? balance,
    required double? maxAllowedBalance,
    required bool isLoading,
    VoidCallback? onRefresh,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final color = AppTheme.warningColor;
    
    // Determine color based on balance percentage
    Color progressColor = AppTheme.successColor;
    if (maxAllowedBalance != null && balance != null) {
      final percentage = balance / maxAllowedBalance;
      if (percentage >= 1.0) {
        progressColor = Colors.red;
      } else if (percentage >= 0.8) {
        progressColor = Colors.orange;
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: color, size: 18),
              if (onRefresh != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onRefresh,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: color,
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Flexible(
            child: isLoading
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        balance != null
                            ? l10n.nis(balance.toStringAsFixed(2))
                            : l10n.nA,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      if (maxAllowedBalance != null && balance != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '/ ${l10n.nis(maxAllowedBalance.toStringAsFixed(2))}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: maxAllowedBalance > 0 ? (balance / maxAllowedBalance).clamp(0.0, 1.0) : 0,
                            minHeight: 4,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.remainingBalance,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    AppLocalizations l10n,
    List<Map<String, dynamic>> orders,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      l10n.filter,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_isTodayFilter || _selectedDate != null)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearFilters();
                        },
                        child: Text(
                          l10n.clear,
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Filter Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Today Option
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Update filter state and apply filters in one operation
                          setState(() {
                            _isTodayFilter = !_isTodayFilter;
                            if (_isTodayFilter) {
                              _selectedDate = null;
                            }
                          });
                          // Get fresh orders from OrderViewModel and apply filters immediately
                          final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
                          final deliveredOrders = _filterDeliveredOrders(orderViewModel.myOrders);
                          // Apply filters synchronously to ensure immediate update
                          _applyFiltersSync(deliveredOrders);
                          _loadDriverBalance();
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isTodayFilter
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isTodayFilter
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300]!,
                              width: _isTodayFilter ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.today_rounded,
                                color: _isTodayFilter
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.today,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _isTodayFilter
                                        ? AppTheme.primaryColor
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (_isTodayFilter)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Select Date Option
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          // Store the current filter state before date picker
                          final wasTodayFilter = _isTodayFilter;
                          await _selectDate(context);
                          // Filters are already applied in _selectDate method
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedDate != null
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedDate != null
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300]!,
                              width: _selectedDate != null ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: _selectedDate != null
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.selectDate,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedDate != null
                                            ? AppTheme.primaryColor
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (_selectedDate != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(_selectedDate!),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (_selectedDate != null)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> order,
  ) {
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
          onTap: () => _showOrderDetailsModal(order),
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
                                      _translateOrderType(l10n, order['type'].toString()),
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
    final dateTime = _parseDate(value);
    if (dateTime == null) return null;
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
}

// Order Details Modal
class _OrderDetailsModal extends StatefulWidget {
  final Map<String, dynamic> order;

  const _OrderDetailsModal({
    required this.order,
  });

  @override
  State<_OrderDetailsModal> createState() => _OrderDetailsModalState();
}

class _OrderDetailsModalState extends State<_OrderDetailsModal> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final order = widget.order;

    // Get order details
    final orderId = _getOrderId(order);
    final displayId = orderId != null && orderId.length > 8
        ? orderId.substring(0, 8)
        : orderId ?? 'N/A';
    final status = (order['status'] ?? '').toString().toLowerCase();
    final orderType = _translateOrderType(l10n, order['type']?.toString() ?? l10n.nA);
    final orderCategory = order['orderCategory']?.toString() ?? l10n.nA;
    final price = order['price']?.toString() ?? '0';
    final createdAt = _formatDateTime(order['createdAt']);

    // Get sender/receiver info
    final senderName = AddressFormatter.getCustomerName(order);
    final senderPhone = AddressFormatter.getCustomerPhone(order);
    final receiverName = order['receiverName']?.toString() ?? l10n.nA;
    final receiverPhone = order['receiverPhoneNumber']?.toString() ?? l10n.nA;

    // Get addresses
    final rawOrderType = order['type']?.toString().toLowerCase().trim() ?? '';
    final isSend = rawOrderType == 'send';
    final pickupAddress = isSend
        ? AddressFormatter.formatAddress(order)
        : '—';
    final deliveryAddress = isSend
        ? '—'
        : AddressFormatter.formatReceiverAddress(order);

    // Status color
    final isDelivered = status == 'delivered';
    final isCancelled = status == 'cancelled';
    final statusColor = isDelivered
        ? AppTheme.successColor
        : isCancelled
            ? AppTheme.errorColor
            : AppTheme.warningColor;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.orderDetails,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#$displayId',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  _buildDetailRow(
                    icon: Icons.info_outline_rounded,
                    label: l10n.status,
                    value: (order['status'] ?? l10n.nA).toString().toUpperCase(),
                    valueColor: statusColor,
                  ),
                  const SizedBox(height: 16),

                  // Order Type
                  _buildDetailRow(
                    icon: Icons.category_rounded,
                    label: l10n.type,
                    value: orderType,
                  ),
                  const SizedBox(height: 16),

                  // Category
                  _buildDetailRow(
                    icon: Icons.shopping_bag_rounded,
                    label: l10n.category,
                    value: orderCategory,
                  ),
                  const SizedBox(height: 16),

                  // Sender Section
                  _buildSectionHeader(l10n.sender),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.person_outline_rounded,
                    label: l10n.name,
                    value: senderName,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.phone_rounded,
                    label: l10n.phone,
                    value: senderPhone,
                  ),
                  const SizedBox(height: 16),

                  // Receiver Section
                  _buildSectionHeader(l10n.receiver),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.person_outline_rounded,
                    label: l10n.name,
                    value: receiverName,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.phone_rounded,
                    label: l10n.phone,
                    value: receiverPhone,
                  ),
                  const SizedBox(height: 16),

                  // Pickup Location
                  _buildDetailRow(
                    icon: Icons.location_on_rounded,
                    label: l10n.pickup,
                    value: pickupAddress,
                  ),
                  const SizedBox(height: 16),

                  // Delivery Location
                  _buildDetailRow(
                    icon: Icons.flag_rounded,
                    label: l10n.dropoff,
                    value: deliveryAddress,
                  ),
                  const SizedBox(height: 16),

                  // Delivery Fee
                  _buildDetailRow(
                    icon: Icons.attach_money_rounded,
                    label: l10n.deliveryFee,
                    value: l10n.nis(price),
                    valueColor: AppTheme.primaryColor,
                    isBold: true,
                  ),
                  const SizedBox(height: 16),

                  // Date & Time
                  _buildDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: l10n.dateTime,
                    value: createdAt ?? l10n.nA,
                  ),
                  const SizedBox(height: 16),

                  // Delivery Notes (if available)
                  if (order['deliveryNotes'] != null &&
                      order['deliveryNotes'].toString().trim().isNotEmpty) ...[
                    _buildSectionHeader(l10n.notes),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        order['deliveryNotes'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: valueColor ?? AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
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
    } else if (normalizedType == 'receive' ||
        normalizedType.contains('receive') ||
        normalizedType.contains('pick')) {
      return l10n.orderTypeReceive;
    }
    return rawType;
  }

  String? _formatDateTime(dynamic value) {
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

    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
