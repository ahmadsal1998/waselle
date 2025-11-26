import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../../view_models/map_style_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final url = Uri.parse(l10n.privacyPolicyUrl);
    
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: Consumer<MapStyleViewModel>(
        builder: (context, mapStyleViewModel, _) {
          final styles = mapStyleViewModel.availableStyles;
          final selectedId = mapStyleViewModel.currentStyle.id;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.mapStyle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...styles.map(
                (style) => RadioListTile<String>(
                  value: style.id,
                  groupValue: selectedId,
                  activeColor: Theme.of(context).colorScheme.primary,
                  title: Text(style.name),
                  subtitle: style.attribution != null
                      ? Text(
                          style.attribution!,
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                  onChanged: (value) async {
                    if (value != null) {
                      await mapStyleViewModel.setStyle(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.privacyPolicy),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openPrivacyPolicy(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

