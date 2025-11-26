import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/locale_view_model.dart';
import '../../view_models/map_style_view_model.dart';
import '../../services/socket_service.dart';
import '../../repositories/api_service.dart';
import 'saved_addresses_screen.dart';

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
      appBar: AppBar(title: Text(l10n.profile)),
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
              backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
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
              backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error opening Terms of Service URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              displayUser['name'] ?? l10n.unknown,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              displayUser['email'] ?? 'Not available',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: isLoggedIn ? FontStyle.normal : FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(l10n.orderHistory),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to order history
              },
            ),
            const Divider(),
            Consumer<LocaleViewModel>(
              builder: (context, localeViewModel, _) {
                final title = localeViewModel.isArabic
                    ? 'إضافة عناوين'
                    : 'Saved Addresses';
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(title),
                  trailing: const Icon(Icons.chevron_right),
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
            const Divider(),
            Consumer<LocaleViewModel>(
              builder: (context, localeViewModel, _) {
                return ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  subtitle: Text(
                    localeViewModel.isArabic ? l10n.arabic : l10n.english,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(l10n.selectLanguage),
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
            Consumer<MapStyleViewModel>(
              builder: (context, mapStyleViewModel, _) {
                return ExpansionTile(
                  leading: const Icon(Icons.map),
                  title: Text(l10n.mapStyle),
                  subtitle: Text(
                    mapStyleViewModel.currentStyle.name,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  children: mapStyleViewModel.availableStyles.map((style) {
                    final isSelected =
                        mapStyleViewModel.currentStyle.id == style.id;
                    return ListTile(
                      title: Text(style.name),
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.blue : null,
                      ),
                      onTap: () {
                        mapStyleViewModel.setStyle(style.id);
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.privacyPolicy),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openPrivacyPolicy(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.termsOfService),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openTermsOfService(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(l10n.settings),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to settings
              },
            ),
            if (isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l10n.logout),
                onTap: () async {
                  await authViewModel.logout();
                  SocketService.disconnect();
                  if (!widget.showAppBar) {
                    // When embedded, ensure outer listeners (e.g. AuthWrapper) react to logout.
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
          ],
        );
      },
    );
  }
}
