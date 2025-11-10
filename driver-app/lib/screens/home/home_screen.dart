import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
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
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.getCurrentLocation();
    
    if (!mounted) return;
    locationProvider.startLocationUpdates();
    await SocketService.initialize();

    if (!mounted) return;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.refreshDriverVehicleType();
    await orderProvider.fetchMyOrders();
  }

  Future<void> _toggleAvailability() async {
    if (!mounted) return;
    setState(() => _isAvailable = !_isAvailable);
    await ApiService.updateAvailability(isAvailable: _isAvailable);

    if (!mounted) return;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    if (_isAvailable) {
      await orderProvider.fetchAvailableOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          Switch(
            value: _isAvailable,
            onChanged: (_) => _toggleAvailability(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('Available')),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          AvailableOrdersScreen(),
          ActiveOrderScreen(),
          OrderHistoryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Available',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Active',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
