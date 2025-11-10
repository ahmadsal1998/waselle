import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/location_provider.dart';
import '../../../providers/order_provider.dart';

class DeliveryRequestForm extends StatefulWidget {
  final String requestType;

  const DeliveryRequestForm({
    super.key,
    required this.requestType,
  });

  @override
  State<DeliveryRequestForm> createState() => _DeliveryRequestFormState();
}

class _DeliveryRequestFormState extends State<DeliveryRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _orderTypeController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _senderAddressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _notesController = TextEditingController();

  Timer? _debounceTimer;
  String? _selectedVehicle;
  double? _estimatedPrice;
  bool _isEstimating = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      if (locationProvider.currentPosition == null &&
          !locationProvider.isLoading) {
        locationProvider.getCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _orderTypeController.dispose();
    _senderNameController.dispose();
    _senderAddressController.dispose();
    _phoneNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onVehicleSelected(String vehicle) {
    if (_selectedVehicle == vehicle) return;
    setState(() => _selectedVehicle = vehicle);
    _scheduleEstimate();
  }

  void _scheduleEstimate() {
    _debounceTimer?.cancel();
    if (_selectedVehicle == null ||
        _senderAddressController.text.trim().isEmpty) {
      setState(() => _estimatedPrice = null);
      return;
    }
    _debounceTimer =
        Timer(const Duration(milliseconds: 500), () => _fetchEstimate());
  }

  Future<void> _fetchEstimate() async {
    if (!mounted || _selectedVehicle == null) return;

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final position = locationProvider.currentPosition;
    final address = _senderAddressController.text.trim();

    final pickupLocation = position != null
        ? {
            'lat': position.latitude,
            'lng': position.longitude,
            if (address.isNotEmpty) 'address': address,
          }
        : (address.isNotEmpty ? {'address': address} : null);

    setState(() {
      _isEstimating = true;
    });

    final cost = await orderProvider.estimateOrderCost(
      vehicleType: _selectedVehicle!,
      pickupLocation: pickupLocation,
      dropoffLocation: pickupLocation,
    );

    if (!mounted) return;

    setState(() {
      _estimatedPrice = cost;
      _isEstimating = false;
    });

    if (cost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to calculate estimated delivery cost.'),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final position = locationProvider.currentPosition;

    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery vehicle.')),
      );
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_estimatedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the estimated cost before submitting.'),
        ),
      );
      return;
    }

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Waiting for your current location. Please enable location services and try again.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final pickupLocation = {
      'lat': position.latitude,
      'lng': position.longitude,
      'address': locationProvider.currentAddress ??
          _senderAddressController.text.trim(),
    };

    final dropoffLocation = {
      'lat': position.latitude,
      'lng': position.longitude,
      'address': _senderAddressController.text.trim(),
    };

    final created = await orderProvider.createOrder(
      type: widget.requestType,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      vehicleType: _selectedVehicle!,
      orderCategory: _orderTypeController.text.trim(),
      senderName: _senderNameController.text.trim(),
      senderAddress: _senderAddressController.text.trim(),
      senderPhoneNumber: _phoneNumberController.text.trim(),
      deliveryNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      estimatedPrice: _estimatedPrice,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (created) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final position = locationProvider.currentPosition;

    if (position == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            color: Theme.of(context).primaryColor.withOpacity(0.08),
            child: ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('Current location'),
              subtitle: Text(
                locationProvider.currentAddress != null
                    ? locationProvider.currentAddress!
                    : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: locationProvider.isLoading
                    ? null
                    : () => locationProvider.getCurrentLocation(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select Delivery Vehicle',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _VehicleOptionButton(
                label: 'Car',
                icon: Icons.directions_car,
                isSelected: _selectedVehicle == 'car',
                onTap: () => _onVehicleSelected('car'),
              ),
              const SizedBox(width: 12),
              _VehicleOptionButton(
                label: 'Bike',
                icon: Icons.pedal_bike,
                isSelected: _selectedVehicle == 'bike',
                onTap: () => _onVehicleSelected('bike'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _orderTypeController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Order Type',
              hintText: 'e.g., Documents, Parcel, Food',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the order type';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _senderNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Sender Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the sender name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _senderAddressController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Sender Address',
              hintText: 'Enter address manually or pick from map',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _scheduleEstimate(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the sender address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a phone number';
              }
              if (value.trim().length < 6) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Delivery Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.attach_money),
                    const SizedBox(width: 8),
                    Text(
                      'Estimated Delivery Cost',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_isEstimating) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _estimatedPrice != null
                      ? '${_estimatedPrice!.toStringAsFixed(2)} NIS'
                      : 'Select a vehicle and enter the address to see the estimate',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'The displayed cost is an estimate and may vary based on actual distance.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Submit Request',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}

class _VehicleOptionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleOptionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = Colors.white;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : unselectedColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedColor : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedColor.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

