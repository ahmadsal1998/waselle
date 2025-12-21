import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';
import '../../view_models/auth_view_model.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/responsive_button.dart';
import 'otp_verification_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final l10n = AppLocalizations.of(context)!;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // Format phone number: convert Arabic digits, remove leading zero, add +972
    final formattedPhone = PhoneUtils.formatPhoneForSubmission(_phoneController.text.trim());
    
    final otpSent = await authViewModel.sendOTP(formattedPhone);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (otpSent) {
      final verified = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(
            phoneNumber: formattedPhone,
          ),
        ),
      );
      
      // Return true if OTP was verified successfully
      if (verified == true && mounted) {
        // If we can pop (opened from another screen), pop with result
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          // Otherwise navigate to home
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage ?? l10n.failedToSendOtp),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.continueWithPhoneNumber),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.phone, size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  l10n.enterPhoneNumber,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.enterPhoneNumberDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    // Only allow numeric characters (0-9)
                    FilteringTextInputFormatter.digitsOnly,
                    // Limit to 10 digits maximum
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumber,
                    hintText: l10n.phoneNumberHint,
                    prefixIcon: const Icon(Icons.phone),
                    prefixText: '+972 ',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.pleaseEnterPhoneNumber;
                    }
                    final trimmed = value.trim();
                    // Check if contains only digits
                    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
                      return l10n.phoneNumberMustBeNumeric;
                    }
                    // Check length: must be 9-10 digits (with or without leading 0)
                    if (trimmed.length < 9 || trimmed.length > 10) {
                      return l10n.pleaseEnterValidPhoneNumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ResponsiveButton.elevated(
                  context: context,
                  onPressed: _isLoading ? null : _handleSendOTP,
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
                          l10n.sendOTP,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

