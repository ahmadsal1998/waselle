import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';
import '../../view_models/auth_view_model.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/responsive_button.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authViewModel.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      // Send OTP to phone number
      final phoneNumber = _phoneController.text.trim();
      if (phoneNumber.isNotEmpty) {
        // Format phone number: convert Arabic digits, remove leading zero, add +972
        final formattedPhone = PhoneUtils.formatPhoneForSubmission(phoneNumber);
        final otpSent = await authViewModel.sendOTP(formattedPhone);
        if (otpSent && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPVerificationScreen(
                phoneNumber: formattedPhone, // Show formatted phone number
              ),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authViewModel.errorMessage ?? 'Failed to send OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      final l10n = AppLocalizations.of(context)!;
      final errorMessage = authViewModel.errorMessage ?? l10n.registrationFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signUp)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.fullName,
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    prefixIcon: const Icon(Icons.email),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterEmail;
                    }
                    if (!value.contains('@')) {
                      return l10n.pleaseEnterValidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Phone number field (accepts Arabic and English digits)
                // Country code +972 is fixed internally and not shown to user
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    // Allow both English and Arabic digits (converted to English in onChanged)
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]')),
                    // Limit to 10 digits maximum
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: '${l10n.phoneNumber} (Optional)',
                    hintText: '0593202026',
                    prefixIcon: const Icon(Icons.phone),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // Convert Arabic digits to English in real-time for display
                    final converted = PhoneUtils.convertArabicToEnglishDigits(value);
                    if (converted != value) {
                      // Update controller with converted value
                      final selection = _phoneController.selection;
                      _phoneController.value = TextEditingValue(
                        text: converted,
                        selection: selection.copyWith(
                          baseOffset: converted.length,
                          extentOffset: converted.length,
                        ),
                      );
                    }
                  },
                  validator: (value) {
                    // Phone number is optional, but if provided, must be valid
                    if (value != null && value.trim().isNotEmpty) {
                      final trimmed = value.trim();
                      // Convert Arabic digits before validation
                      final converted = PhoneUtils.convertArabicToEnglishDigits(trimmed);
                      final digitsOnly = converted.replaceAll(RegExp(r'[^\d]'), '');
                      
                      // Check if contains only digits
                      if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
                        return l10n.phoneNumberMustBeNumeric;
                      }
                      // Check length: must be 9-10 digits (with or without leading 0)
                      if (digitsOnly.length < 9 || digitsOnly.length > 10) {
                        return l10n.pleaseEnterValidPhoneNumber;
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterPassword;
                    }
                    if (value.length < 6) {
                      return l10n.passwordMustBe6Chars;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ResponsiveButton.elevated(
                  context: context,
                  onPressed: _isLoading ? null : _handleRegister,
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
                          l10n.signUp,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
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
