import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/location_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/region_provider.dart';
import 'controllers/delivery_request_form_controller.dart';
import 'views/delivery_request_form_view.dart';

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
  late final DeliveryRequestFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DeliveryRequestFormController(requestType: widget.requestType);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = context.read<LocationProvider>();
      final regionProvider = context.read<RegionProvider>();
      final orderProvider = context.read<OrderProvider>();

      _controller.initialize(
        locationProvider: locationProvider,
        regionProvider: regionProvider,
        orderProvider: orderProvider,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final regionProvider = context.watch<RegionProvider>();
    final orderProvider = context.watch<OrderProvider>();

    _controller.syncOrderCategorySelection(orderProvider);

    return ChangeNotifierProvider<DeliveryRequestFormController>.value(
      value: _controller,
      child: DeliveryRequestFormView(
        locationProvider: locationProvider,
        regionProvider: regionProvider,
        orderProvider: orderProvider,
      ),
    );
  }
}

