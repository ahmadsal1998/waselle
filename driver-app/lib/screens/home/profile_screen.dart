import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/locale_view_model.dart';
import '../../view_models/map_style_view_model.dart';
import '../../view_models/order_view_model.dart';
import '../../services/socket_service.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/api_client.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingPicture = false;
  String? _privacyPolicyUrl;
  String? _termsOfServiceUrl;

  @override
  void initState() {
    super.initState();
    _loadLegalUrls();
  }

  Future<void> _loadLegalUrls() async {
    try {
      final urls = await ApiClient.getLegalUrls();
      if (mounted) {
        setState(() {
          _privacyPolicyUrl = urls['privacyPolicyUrl'];
          _termsOfServiceUrl = urls['termsOfServiceUrl'];
        });
      }
    } catch (e) {
      debugPrint('Error loading legal URLs: $e');
      // Fallback to default URLs from localization
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _privacyPolicyUrl = l10n.privacyPolicyUrl;
          _termsOfServiceUrl = l10n.termsOfServiceUrl ?? 'https://www.wassle.ps/terms-of-service';
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_isUploadingPicture) return;

    final l10n = AppLocalizations.of(context)!;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Show image source dialog
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          l10n.selectImageSource,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: Text(l10n.camera),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: Text(l10n.gallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      // Pick image with timeout handling
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85, // Compress to 85% quality
        maxWidth: 1024, // Limit width
        maxHeight: 1024, // Limit height
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Image picker timed out');
        },
      );

      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);

      // Validate image
      final validationError = CloudinaryService.validateImage(imageFile);
      if (validationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationError),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      setState(() => _isUploadingPicture = true);

      // Upload to Cloudinary
      final imageUrl = await CloudinaryService.uploadImage(imageFile);

      // Update backend
      final success = await authViewModel.updateProfilePicture(imageUrl);

      if (!mounted) return;

      setState(() => _isUploadingPicture = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profilePictureUpdated),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToUpdateProfilePicture),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isUploadingPicture = false);

      String errorMessage;
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('platformexception') || 
          errorString.contains('channel-error') ||
          errorString.contains('unable to establish connection') ||
          errorString.contains('pigeon')) {
        errorMessage = 'Image picker is not available. Please stop the app completely and rebuild it, then try again.';
      } else if (errorString.contains('timeout')) {
        errorMessage = 'Image selection timed out. Please try again.';
      } else if (errorString.contains('permission') || errorString.contains('denied')) {
        errorMessage = 'Permission denied. Please enable camera/photos access in Settings.';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('TimeoutException: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final urlString = _privacyPolicyUrl ?? l10n.privacyPolicyUrl;
    final url = Uri.parse(urlString);
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.unableToOpenPrivacyPolicy),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        debugPrint('Error: Unable to launch Privacy Policy URL: ${url.toString()}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.unableToOpenPrivacyPolicy),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      debugPrint('Error opening Privacy Policy URL: $e');
    }
  }

  Future<void> _openTermsOfService(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final urlString = _termsOfServiceUrl ?? l10n.termsOfServiceUrl ?? 'https://www.wassle.ps/terms-of-service';
    final url = Uri.parse(urlString);
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.unableToOpenTermsOfService ?? 'Unable to open Terms of Service. Please check your internet connection.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        debugPrint('Error: Unable to launch Terms of Service URL: ${url.toString()}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.unableToOpenTermsOfService ?? 'Unable to open Terms of Service. Please check your internet connection.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      debugPrint('Error opening Terms of Service URL: $e');
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    if (!mounted) return;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final previous = authViewModel.isAvailable;
    final success = await authViewModel.setAvailability(value);

    if (!mounted) return;

    if (success) {
      if (value) {
        final orderViewModel =
            Provider.of<OrderViewModel>(context, listen: false);
        await orderViewModel.fetchAvailableOrders();
      }
    } else {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToUpdateAvailability),
        ),
      );
      if (previous != value && mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        final user = authViewModel.user;
        final isAvailable = authViewModel.isAvailable;
        final isLoggedIn = user != null;

        // Create default placeholder values when user is not logged in
        final displayUser = user ?? {
          'name': l10n.unknown,
          'email': 'Not available',
          'phone': 'Not available',
          'profilePicture': null,
        };

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // Modern Header with Gradient
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                boxShadow: ModernCardShadow.medium,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: isLoggedIn ? _pickAndUploadImage : null,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: ModernCardShadow.light,
                              ),
                              child: ClipOval(
                                child: displayUser['profilePicture'] != null &&
                                        (displayUser['profilePicture'] as String).isNotEmpty
                                    ? Image.network(
                                        displayUser['profilePicture'] as String,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              gradient: AppTheme.primaryGradient,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.person_rounded,
                                              size: 50,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              gradient: AppTheme.primaryGradient,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.primaryGradient,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            if (isLoggedIn && _isUploadingPicture)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            else if (isLoggedIn)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        displayUser['name'] ?? l10n.unknown,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          displayUser['email'] ?? 'Not available',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontStyle: isLoggedIn ? FontStyle.normal : FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Availability Toggle (only show if logged in)
                  if (isLoggedIn)
                    _AvailabilityToggleTile(
                      isAvailable: isAvailable,
                      onToggle: _toggleAvailability,
                    ),
                  if (isLoggedIn) const SizedBox(height: 12),
                  Consumer<LocaleViewModel>(
                    builder: (context, localeViewModel, _) {
                      return _ModernProfileTile(
                        icon: Icons.language_rounded,
                        title: l10n.language,
                        subtitle: localeViewModel.isArabic ? l10n.arabic : l10n.english,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  l10n.selectLanguage,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RadioListTile<Locale>(
                                      title: Text(l10n.english),
                                      value: const Locale('en'),
                                      groupValue: localeViewModel.locale,
                                      onChanged: (Locale? value) {
                                        if (value != null) {
                                          localeViewModel.setLocale(value);
                                          Navigator.of(context).pop();
                                        }
                                      },
                                    ),
                                    RadioListTile<Locale>(
                                      title: Text(l10n.arabic),
                                      value: const Locale('ar'),
                                      groupValue: localeViewModel.locale,
                                      onChanged: (Locale? value) {
                                        if (value != null) {
                                          localeViewModel.setLocale(value);
                                          Navigator.of(context).pop();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Consumer<MapStyleViewModel>(
                    builder: (context, mapStyleViewModel, _) {
                      return _ModernProfileTile(
                        icon: Icons.map_rounded,
                        title: l10n.settings,
                        subtitle: l10n.mapStyleValue(mapStyleViewModel.currentStyle.name),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ModernProfileTile(
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.privacyPolicy,
                    subtitle: 'View our Privacy Policy',
                    onTap: () => _openPrivacyPolicy(context),
                  ),
                  const SizedBox(height: 12),
                  _ModernProfileTile(
                    icon: Icons.description_outlined,
                    title: l10n.termsOfService,
                    subtitle: 'View our Terms of Service',
                    onTap: () => _openTermsOfService(context),
                  ),
                  const SizedBox(height: 24),
                  if (isLoggedIn)
                    _ModernProfileTile(
                      icon: Icons.logout_rounded,
                      title: l10n.logout,
                      subtitle: 'Sign out from your account',
                      isDestructive: true,
                      onTap: () async {
                        await authViewModel.logout();
                        SocketService.disconnect();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          );
                        }
                      },
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AvailabilityToggleTile extends StatelessWidget {
  final bool isAvailable;
  final Future<void> Function(bool) onToggle;

  const _AvailabilityToggleTile({
    required this.isAvailable,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ModernCardShadow.light,
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.available,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAvailable ? l10n.available : 'Not Available',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isAvailable,
              onChanged: (value) => onToggle(value),
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ModernProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.errorColor : AppTheme.primaryColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ModernCardShadow.light,
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
