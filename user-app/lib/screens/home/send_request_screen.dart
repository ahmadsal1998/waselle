import 'package:flutter/material.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';
import '../../widgets/home/delivery_request_form.dart';

class SendRequestScreen extends StatelessWidget {
  const SendRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sendRequest)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: const DeliveryRequestForm(requestType: 'send'),
        ),
      ),
    );
  }
}
