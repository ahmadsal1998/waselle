import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../view_models/location_view_model.dart';
import '../../../view_models/order_view_model.dart';
import '../../../view_models/region_view_model.dart';
import '../../../view_models/auth_view_model.dart';
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
    _controller =
        DeliveryRequestFormController(requestType: widget.requestType);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = context.read<LocationViewModel>();
      final regionProvider = context.read<RegionViewModel>();
      final orderProvider = context.read<OrderViewModel>();
      final authProvider = context.read<AuthViewModel>();

      _controller.initialize(
        locationProvider: locationProvider,
        regionProvider: regionProvider,
        orderProvider: orderProvider,
        authProvider: authProvider,
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
    final locationProvider = context.watch<LocationViewModel>();
    final regionProvider = context.watch<RegionViewModel>();
    final orderProvider = context.watch<OrderViewModel>();

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
