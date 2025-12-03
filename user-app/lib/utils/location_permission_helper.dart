import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';

/// Helper class for handling location permission requests with user-friendly dialogs
class LocationPermissionHelper {
  /// Shows a dialog explaining why location is needed before requesting permission
  /// Returns true if user wants to proceed with permission request, false if denied
  static Future<bool> showLocationPermissionDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.locationPermissionTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.locationPermissionMessage,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.denyLocation,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.allowLocation),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Requests location permission after showing the dialog
  /// Returns the permission status
  static Future<LocationPermission> requestLocationPermissionWithDialog(
    BuildContext context,
  ) async {
    // Check if permission is already granted
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      // Show dialog first
      final shouldProceed = await showLocationPermissionDialog(context);
      
      if (!shouldProceed) {
        // User chose to deny in the dialog
        return LocationPermission.denied;
      }
      
      // User chose to allow - now request the actual permission
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  /// Shows a message when location permission is denied
  static void showLocationDeniedMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.locationDeniedMessage),
        duration: const Duration(seconds: 5),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Shows a dialog with location permission result after iOS system dialog is dismissed
  static void showLocationPermissionResult(
    BuildContext context,
    LocationPermission permission,
  ) {
    final l10n = AppLocalizations.of(context)!;

    // Show dialog after a short delay to ensure system dialog is dismissed
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!context.mounted) return;
      
      final currentL10n = AppLocalizations.of(context);
      if (currentL10n == null) return;

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Permission granted - show success message
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => AlertDialog(
            title: Text(currentL10n.locationPermissionGranted),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  currentL10n.locationPermissionGrantedMessage,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(currentL10n.ok),
              ),
            ],
          ),
        );
      } else if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Permission denied - show informative message
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => AlertDialog(
            title: Text(currentL10n.locationPermissionDenied),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  currentL10n.locationPermissionDeniedMessage,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(currentL10n.ok),
              ),
            ],
          ),
        );
      }
    });
  }
}

