import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/map_style_provider.dart';
import '../../services/socket_service.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: content,
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final bool showAppBar;

  const _ProfileContent({required this.showAppBar});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;

        if (user == null) {
          return const Center(child: Text('No user data'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              user['name'] ?? 'Unknown',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              user['email'] ?? '',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Order History'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to order history
              },
            ),
            const Divider(),
            Consumer<MapStyleProvider>(
              builder: (context, mapStyleProvider, _) {
                return ExpansionTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Map Style'),
                  subtitle: Text(
                    mapStyleProvider.currentStyle.name,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  children: mapStyleProvider.availableStyles.map((style) {
                    final isSelected =
                        mapStyleProvider.currentStyle.id == style.id;
                    return ListTile(
                      title: Text(style.name),
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.blue : null,
                      ),
                      onTap: () {
                        mapStyleProvider.setStyle(style.id);
                      },
                    );
                  }).toList(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await authProvider.logout();
                SocketService.disconnect();
                if (!showAppBar) {
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
