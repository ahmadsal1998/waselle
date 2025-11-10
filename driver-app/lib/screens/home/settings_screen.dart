import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/map_style_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<MapStyleProvider>(
        builder: (context, mapStyleProvider, _) {
          final styles = mapStyleProvider.availableStyles;
          final selectedId = mapStyleProvider.currentStyle.id;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Map Style',
                style: TextStyle(
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
                      await mapStyleProvider.setStyle(value);
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

