import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../view_models/auth_view_model.dart';
import '../utils/phone_utils.dart';

class DeleteAccountOTPDialog extends StatefulWidget {
  final String phoneNumber;

  const DeleteAccountOTPDialog({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<DeleteAccountOTPDialog> createState() => _DeleteAccountOTPDialogState();
}

class _DeleteAccountOTPDialogState extends State<DeleteAccountOTPDialog> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingOtp = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  bool _hasSentInitialOtp = false;

  @override
  void initState() {
    super.initState();
    // Defer OTP sending until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasSentInitialOtp) {
        _hasSentInitialOtp = true;
        _sendOTP();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isSendingOtp = true;
    });

    final l10n = AppLocalizations.of(context)!;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // Normalize phone number
    final normalizedPhone = PhoneUtils.normalizePhoneNumber(widget.phoneNumber);
    if (normalizedPhone == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToSendOtp)),
        );
      }
      setState(() => _isSendingOtp = false);
      return;
    }

    final success = await authViewModel.sendOTP(normalizedPhone);
    
    setState(() => _isSendingOtp = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.otpSentSuccessfully)),
      );
      _startResendCountdown();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage ?? l10n.failedToSendOtp),
        ),
      );
    }
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyAndDelete() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterValidOtp)),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // Normalize phone number
    final normalizedPhone = PhoneUtils.normalizePhoneNumber(widget.phoneNumber);
    if (normalizedPhone == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToDeleteAccount)),
      );
      return;
    }

    final success = await authViewModel.deleteAccount(
      phoneNumber: normalizedPhone,
      otp: _otpController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountDeletedSuccessfully)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage ?? l10n.failedToDeleteAccount),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        l10n.deleteAccountOtpTitle,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.deleteAccountOtpMessage(widget.phoneNumber),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
              enabled: !_isLoading && !_isSendingOtp,
            ),
            const SizedBox(height: 16),
            if (_isSendingOtp)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              )
            else if (_resendCountdown > 0)
              Text(
                l10n.resendOtpIn(_resendCountdown),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              )
            else
              TextButton(
                onPressed: _sendOTP,
                child: Text(l10n.resendOtp),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: (_isLoading || _isSendingOtp) ? null : _verifyAndDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.delete),
        ),
      ],
    );
  }
}

