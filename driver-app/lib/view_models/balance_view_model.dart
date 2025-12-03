import 'package:flutter/foundation.dart';
import '../repositories/user_repository.dart';
import '../services/socket_service.dart';

class BalanceViewModel with ChangeNotifier {
  BalanceViewModel({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  final UserRepository _userRepository;

  double? _driverBalance;
  double? _maxAllowedBalance;
  bool _isLoading = false;
  bool _listenersSetup = false;

  double? get driverBalance => _driverBalance;
  double? get maxAllowedBalance => _maxAllowedBalance;
  bool get isLoading => _isLoading;

  /// Setup socket listeners to automatically refresh balance when orders are completed
  /// Should be called after socket is initialized
  void setupSocketListeners() {
    if (_listenersSetup) return;
    
    debugPrint('BalanceViewModel: Setting up socket listeners');
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Remove old listeners first
    SocketService.off('order-updated');
    SocketService.off('order-status-changed');
    
    // Listen for order updates - when an order is delivered, refresh balance
    SocketService.on('order-updated', (data) {
      if (data is Map<String, dynamic>) {
        final order = Map<String, dynamic>.from(data);
        final status = (order['status'] ?? '').toString().toLowerCase();
        
        // If order is delivered, automatically refresh balance
        if (status == 'delivered') {
          debugPrint('BalanceViewModel: Order delivered, auto-refreshing balance');
          refreshBalance();
        }
      }
    });

    // Listen for order status changes via socket
    SocketService.on('order-status-changed', (data) {
      if (data is Map<String, dynamic>) {
        final status = (data['status'] ?? '').toString().toLowerCase();
        if (status == 'delivered') {
          debugPrint('BalanceViewModel: Order status changed to delivered, auto-refreshing balance');
          refreshBalance();
        }
      }
    });

    // Listen for socket connection to re-setup listeners
    SocketService.off('connect');
    SocketService.on('connect', (_) {
      debugPrint('BalanceViewModel: Socket connected, re-setting up listeners');
      _listenersSetup = false;
      setupSocketListeners();
    });

    _listenersSetup = true;
    debugPrint('BalanceViewModel: Socket listeners setup complete');
  }

  /// Refresh balance from server
  Future<void> refreshBalance() async {
    if (_isLoading) {
      debugPrint('BalanceViewModel: Already loading balance, skipping...');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _userRepository.getMyBalance();
      if (response['balanceInfo'] != null) {
        final balanceInfo = response['balanceInfo'] as Map<String, dynamic>;
        _driverBalance = (balanceInfo['currentBalance'] as num?)?.toDouble();
        _maxAllowedBalance = (balanceInfo['maxAllowedBalance'] as num?)?.toDouble();
        debugPrint('BalanceViewModel: Balance refreshed - Current: $_driverBalance, Max: $_maxAllowedBalance');
      } else {
        debugPrint('BalanceViewModel: No balanceInfo in response');
      }
    } catch (e) {
      debugPrint('BalanceViewModel: Error refreshing balance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load balance initially (called on screen init)
  Future<void> loadBalance() async {
    // Only load if we don't have balance data yet
    if (_driverBalance == null && !_isLoading) {
      await refreshBalance();
    }
  }
}

