import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/location_view_model.dart';
import '../../view_models/order_view_model.dart';
import '../../services/socket_service.dart';
import '../auth/suspended_account_screen.dart';
import 'available_orders_screen.dart';
import 'active_order_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // Check if account is suspended before proceeding
    await authViewModel.refreshCurrentUser();
    if (!mounted) return;
    
    if (authViewModel.isSuspended) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SuspendedAccountScreen()),
      );
      return;
    }
    
    final locationViewModel =
        Provider.of<LocationViewModel>(context, listen: false);
    await locationViewModel.getCurrentLocation();
    
    if (!mounted) return;
    locationViewModel.startLocationUpdates();
    
    // Initialize socket
    await SocketService.initialize();
    
    // Wait for socket to connect (with timeout)
    final connected = await SocketService.waitForConnection(maxWaitMs: 3000);
    if (!connected) {
      debugPrint('Warning: Socket did not connect within timeout');
    } else {
      debugPrint('Socket connected successfully');
    }

    if (!mounted) return;
    final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
    
    // Setup socket listeners after socket is initialized
    orderViewModel.setupSocketListeners();
    
    // Setup call listener
    _setupCallListener();
    
    // Wait a bit more to ensure listeners are attached
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Load vehicle type from user profile
    final user = authViewModel.user;
    final vehicleType = user?['vehicleType'] as String?;
    orderViewModel.setDriverVehicleType(vehicleType);
    debugPrint('HomeScreen: Driver vehicle type from user profile: $vehicleType');
    
    await orderViewModel.refreshDriverVehicleType();
    await orderViewModel.fetchMyOrders();
    // Fetch available orders to populate the list initially
    await orderViewModel.fetchAvailableOrders();
    
    // Check if we need to navigate to Available Orders screen (from notification)
    _checkPendingNavigation();
  }
  
  /// Check for pending navigation from notification
  Future<void> _checkPendingNavigation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shouldNavigate = prefs.getBool('navigate_to_available_orders') ?? false;
      
      if (shouldNavigate) {
        // Clear the flag
        await prefs.remove('navigate_to_available_orders');
        
        // Navigate to Available Orders screen (index 0)
        if (mounted) {
          setState(() {
            _currentIndex = 0;
          });
          debugPrint('✅ Navigated to Available Orders screen from notification');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking pending navigation: $e');
    }
  }
  
  void _checkSuspensionStatus() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.isSuspended) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SuspendedAccountScreen()),
      );
    }
  }

  void _setupCallListener() {
    SocketService.on('incoming-call', (data) {
      if (!mounted) return;
      
      final orderId = data['orderId']?.toString();
      final roomId = data['roomId']?.toString();
      final callerId = data['callerId']?.toString();
      final callerName = data['callerName']?.toString() ?? 'Unknown';
      
      if (orderId == null || roomId == null || callerId == null) {
        debugPrint('Error: Invalid incoming call data');
        return;
      }
      
      debugPrint('📞 RECEIVER: Received incoming call notification');
      debugPrint('   - callerName: $callerName');
      debugPrint('   - orderId: $orderId');
      debugPrint('   - roomId (from server): $roomId');
      debugPrint('   - callerId: $callerId');
      debugPrint('   - Will use this EXACT roomId when accepting call');
      
      // Call functionality removed - ZegoUIKitPrebuiltCall dependency removed
      // Incoming call handling disabled
    });
    
    SocketService.on('call-cancelled', (data) {
      if (!mounted) return;
      
      final roomId = data['roomId']?.toString();
      final callerId = data['callerId']?.toString();
      
      if (roomId == null || callerId == null) {
        debugPrint('Error: Invalid call cancellation data');
        return;
      }
      
      debugPrint('🚫 Call cancelled: Caller $callerId disconnected');
      
      // Call functionality removed - ZegoUIKitPrebuiltCall dependency removed
      // Call cancellation handling disabled
    });
  }


  String _getAppBarTitle(AppLocalizations l10n) {
    switch (_currentIndex) {
      case 0:
        return l10n.available;
      case 1:
        return l10n.activeOrder;
      case 2:
        return l10n.orderHistory;
      case 3:
        return l10n.profile;
      default:
        return l10n.driverDashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orderViewModel = context.watch<OrderViewModel>();
    final activeOrdersCount = orderViewModel.activeOrders.length;
    final availableOrdersCount = orderViewModel.availableOrders.length;
    final authViewModel = context.watch<AuthViewModel>();
    
    // Check suspension status whenever widget rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authViewModel.isSuspended) {
        _checkSuspensionStatus();
      }
    });
    
    return Scaffold(
      body: Column(
        children: [
          // Modern Header
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              boxShadow: ModernCardShadow.medium,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getAppBarTitle(l10n),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body Content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                AvailableOrdersScreen(),
                ActiveOrderScreen(),
                OrderHistoryScreen(),
                ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ModernNavItem(
                  icon: Icons.inbox_outlined,
                  activeIcon: Icons.inbox_rounded,
                  label: l10n.available,
                  isActive: _currentIndex == 0,
                  badge: availableOrdersCount > 0 ? availableOrdersCount : null,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _ModernNavItem(
                  icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping_rounded,
                  label: l10n.active,
                  isActive: _currentIndex == 1,
                  badge: activeOrdersCount > 0 ? activeOrdersCount : null,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _ModernNavItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: l10n.history,
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _ModernNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: l10n.profile,
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _ModernNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    this.badge,
    required this.onTap,
  });

  @override
  State<_ModernNavItem> createState() => _ModernNavItemState();
}

class _ModernNavItemState extends State<_ModernNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ModernNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _animationController.forward().then((_) {
              _animationController.reverse();
            });
            widget.onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.isActive
                                  ? AppTheme.primaryColor.withOpacity(0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.isActive ? widget.activeIcon : widget.icon,
                              color: widget.isActive
                                  ? AppTheme.primaryColor
                                  : AppTheme.textTertiary,
                              size: 24,
                            ),
                          ),
                          if (widget.badge != null && widget.badge! > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppTheme.errorColor,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  widget.badge! > 9 ? '9+' : widget.badge.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: widget.isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: widget.isActive
                                ? AppTheme.primaryColor
                                : AppTheme.textTertiary,
                            height: 1.1,
                          ),
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
