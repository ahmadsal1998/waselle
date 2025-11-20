import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../../view_models/auth_view_model.dart';

class SuspendedAccountScreen extends StatefulWidget {
  const SuspendedAccountScreen({super.key});

  @override
  State<SuspendedAccountScreen> createState() => _SuspendedAccountScreenState();
}

class _SuspendedAccountScreenState extends State<SuspendedAccountScreen> with WidgetsBindingObserver {
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Don't auto-check on init to prevent reload loops
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check status when app comes to foreground
    if (mounted && state == AppLifecycleState.resumed) {
      _checkAccountStatus();
    }
  }

  Future<void> _checkAccountStatus() async {
    if (!mounted) return;

    setState(() {
      _isCheckingStatus = true;
    });

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.refreshCurrentUser();

      if (!mounted) return;

      setState(() {
        _isCheckingStatus = false;
      });

      // If account is now active, navigate back to home
      if (authViewModel.isAuthenticated && !authViewModel.isSuspended) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.user;
    
    // Get balance info if available
    final balance = user?['balance'] as num?;
    final maxAllowedBalance = user?['maxAllowedBalance'] as num?;

    return PopScope(
      // Prevent back button navigation
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                const Icon(
                  Icons.block,
                  size: 100,
                  color: Colors.red,
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Account Suspended',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Message
                Text(
                  'Your account has been suspended due to an outstanding balance.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please contact the administrator to make a payment and reactivate your account.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Balance Information (if available)
                if (balance != null || maxAllowedBalance != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      children: [
                        if (balance != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Current Balance:',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${balance.toStringAsFixed(2)} NIS',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (maxAllowedBalance != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Maximum Allowed:',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${maxAllowedBalance.toStringAsFixed(2)} NIS',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                
                // Check Status Button
                ElevatedButton.icon(
                  onPressed: _isCheckingStatus ? null : _checkAccountStatus,
                  icon: _isCheckingStatus
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isCheckingStatus ? 'Checking...' : 'Check Account Status'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Logout Button
                OutlinedButton.icon(
                  onPressed: () async {
                    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
                    await authViewModel.logout();
                    if (!mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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

