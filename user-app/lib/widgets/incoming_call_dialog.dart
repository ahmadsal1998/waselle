import 'dart:async';
import 'package:flutter/material.dart';

class IncomingCallDialog extends StatefulWidget {
  final String callerName;
  final String orderId;
  final String roomId;
  final String callerId;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final int timeoutSeconds;

  const IncomingCallDialog({
    super.key,
    required this.callerName,
    required this.orderId,
    required this.roomId,
    required this.callerId,
    required this.onAccept,
    required this.onReject,
    this.timeoutSeconds = 30,
  });

  @override
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog> {
  Timer? _timeoutTimer;
  int _remainingSeconds = 30;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeoutSeconds;
    _startTimeout();
  }

  void _startTimeout() {
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    if (mounted) {
      Navigator.of(context).pop();
      widget.onReject(); // Auto-reject on timeout
    }
  }

  void _handleAccept() {
    _timeoutTimer?.cancel();
    Navigator.of(context).pop();
    widget.onAccept();
  }

  void _handleReject() {
    _timeoutTimer?.cancel();
    Navigator.of(context).pop();
    widget.onReject();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleReject();
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Caller Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Caller Name
              Text(
                widget.callerName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Incoming Call Text
              Text(
                'Incoming Voice Call',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              
              // Timeout Counter
              Text(
                '${_remainingSeconds}s',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleReject,
                      icon: const Icon(Icons.call_end),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Accept Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleAccept,
                      icon: const Icon(Icons.call),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

