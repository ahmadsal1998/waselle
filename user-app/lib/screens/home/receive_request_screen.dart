import 'package:flutter/material.dart';
import 'widgets/delivery_request_form.dart';

class ReceiveRequestScreen extends StatelessWidget {
  const ReceiveRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Request')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: const DeliveryRequestForm(requestType: 'receive'),
        ),
      ),
    );
  }
}