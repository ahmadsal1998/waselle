import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/locale_view_model.dart';
import '../../view_models/map_style_view_model.dart';
import '../../services/socket_service.dart';
import '../../repositories/api_service.dart';
import '../../theme/app_theme.dart';
import 'saved_addresses_screen.dart';
import 'order_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool showAppBar;

  const ProfileScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = _ProfileContent(showAppBar: showAppBar);

    if (!showAppBar) {
      return content;
    }

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        elevation: 0,
      ),
      body: content,
    );
  }
}

class _ProfileContent extends StatefulWidget {
  final bool showAppBar;

  const _ProfileContent({required this.showAppBar});

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  String? _privacyPolicyUrl;
  String? _termsOfServiceUrl;
  bool _isLoadingUrls = true;

  @override
  void initState() {
    super.initState();
    _loadLegalUrls();
  }

  Future<void> _loadLegalUrls() async {
    try {
      final urls = await ApiService.getLegalUrls();
      if (mounted) {
        setState(() {
          _privacyPolicyUrl = urls['privacyPolicyUrl'];
          _termsOfServiceUrl = urls['termsOfServiceUrl'];
          _isLoadingUrls = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading legal URLs: $e');
      // Fallback to default URLs from localization
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _privacyPolicyUrl = l10n.privacyPolicyUrl;
          _termsOfServiceUrl = l10n.termsOfServiceUrl;
          _isLoadingUrls = false;
        });
      }
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
        if (context.mounted) {
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
      if (context.mounted) {
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
    final urlString = _termsOfServiceUrl ?? l10n.termsOfServiceUrl;
    final url = Uri.parse(urlString);
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.unableToOpenTermsOfService),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        debugPrint('Error: Unable to launch Terms of Service URL: ${url.toString()}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.unableToOpenTermsOfService),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      debugPrint('Error opening Terms of Service URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        final user = authViewModel.user;
        final isLoggedIn = user != null;

        // Create default placeholder values when user is not logged in
        final displayUser = user ?? {
          'name': l10n.unknown,
          'email': 'Not available',
          'phone': 'Not available',
        };

        return Container(
          color: colorScheme.background,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Profile Header Section
              _ProfileHeader(
                userName: displayUser['name'] ?? l10n.unknown,
                userEmail: displayUser['email'] ?? 'Not available',
                isLoggedIn: isLoggedIn,
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions Section
              _SectionCard(
                title: null,
                children: [
                  _ModernProfileTile(
                    icon: Icons.history_rounded,
                    iconColor: AppTheme.primaryColor,
                    title: l10n.orderHistory,
                    subtitle: 'View your past orders',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const OrderHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Consumer<LocaleViewModel>(
                    builder: (context, localeViewModel, _) {
                      final title = localeViewModel.isArabic
                          ? 'إضافة عناوين'
                          : 'Saved Addresses';
                      return _ModernProfileTile(
                        icon: Icons.location_on_rounded,
                        iconColor: AppTheme.secondaryColor,
                        title: title,
                        subtitle: 'Manage your saved addresses',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SavedAddressesScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Settings Section
              _SectionCard(
                title: l10n.settings,
                children: [
                  Consumer<LocaleViewModel>(
                    builder: (context, localeViewModel, _) {
                      return _ModernProfileTile(
                        icon: Icons.language_rounded,
                        iconColor: AppTheme.primaryColor,
                        title: l10n.language,
                        subtitle: localeViewModel.isArabic ? l10n.arabic : l10n.english,
                        onTap: () {
                          _showLanguageDialog(context, localeViewModel, l10n);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Consumer<MapStyleViewModel>(
                    builder: (context, mapStyleViewModel, _) {
                      return _ModernProfileTile(
                        icon: Icons.map_rounded,
                        iconColor: AppTheme.secondaryColor,
                        title: l10n.mapStyle,
                        subtitle: mapStyleViewModel.currentStyle.name,
                        onTap: () {
                          _showMapStyleBottomSheet(context, mapStyleViewModel);
                        },
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Legal Section
              _SectionCard(
                title: 'Legal',
                children: [
                  _ModernProfileTile(
                    icon: Icons.privacy_tip_rounded,
                    iconColor: AppTheme.textSecondary,
                    title: l10n.privacyPolicy,
                    subtitle: 'Read our privacy policy',
                    onTap: () => _openPrivacyPolicy(context),
                  ),
                  const SizedBox(height: 8),
                  _ModernProfileTile(
                    icon: Icons.description_rounded,
                    iconColor: AppTheme.textSecondary,
                    title: l10n.termsOfService,
                    subtitle: 'Read our terms of service',
                    onTap: () => _openTermsOfService(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Logout Button
              if (isLoggedIn)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _LogoutButton(
                    label: l10n.logout,
                    onTap: () async {
                      await authViewModel.logout();
                      SocketService.disconnect();
                      if (!widget.showAppBar) {
                        return;
                      }
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/',
                          (route) => false,
                        );
                      }
                    },
                  ),
                ),
              
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    LocaleViewModel localeViewModel,
    AppLocalizations l10n,
  ) {
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
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageOption(
                title: l10n.english,
                isSelected: localeViewModel.locale == const Locale('en'),
                onTap: () {
                  localeViewModel.setLocale(const Locale('en'));
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                title: l10n.arabic,
                isSelected: localeViewModel.locale == const Locale('ar'),
                onTap: () {
                  localeViewModel.setLocale(const Locale('ar'));
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMapStyleBottomSheet(
    BuildContext context,
    MapStyleViewModel mapStyleViewModel,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Select Map Style',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              ...mapStyleViewModel.availableStyles.map((style) {
                final isSelected = mapStyleViewModel.currentStyle.id == style.id;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  ),
                  title: Text(style.name),
                  onTap: () {
                    mapStyleViewModel.setStyle(style.id);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

// Profile Header Widget
class _ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final bool isLoggedIn;

  const _ProfileHeader({
    required this.userName,
    required this.userEmail,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryLight,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // User Name
          Text(
            userName,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // User Email
          Text(
            userEmail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontStyle: isLoggedIn ? FontStyle.normal : FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Section Card Widget
class _SectionCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SectionCard({
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ),
            const Divider(height: 1),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(16, title != null ? 8 : 16, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// Modern Profile Tile Widget
class _ModernProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModernProfileTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              
              // Chevron Icon
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textTertiary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Language Option Widget
class _LanguageOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Logout Button Widget
class _LogoutButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LogoutButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.errorColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppTheme.errorColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.errorColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
