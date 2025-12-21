import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';
import '../../view_models/auth_view_model.dart';
import '../../widgets/responsive_button.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterValidOtp)),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authViewModel.verifyOTP(
      phoneNumber: widget.phoneNumber,
      otp: _otpController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      // Return true to indicate successful verification
      // Check if we can pop (if opened from phone login screen)
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        // Navigate to home if this was opened directly
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authViewModel.errorMessage ?? l10n.invalidOtp)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyYourPhone)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.phone, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                l10n.verifyYourPhone,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.otpSentMessage(widget.phoneNumber),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: '000000',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ResponsiveButton.elevated(
                context: context,
                onPressed: _isLoading ? null : _verifyOTP,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.verify,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
