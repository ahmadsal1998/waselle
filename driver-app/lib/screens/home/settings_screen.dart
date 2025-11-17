import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../../view_models/map_style_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                  activeColor: Colors.green,
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
            ],
          );
        },
      ),
    );
  }
}

