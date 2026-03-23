// lib/widgets/side_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class SideNavBar extends ConsumerWidget {
  final String userName;
  const SideNavBar({super.key, required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final themeNotifier = ref.read(themeModeNotifierProvider.notifier);
    final bool isDarkMode = themeMode == ThemeMode.dark;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text("IFCM Tunes Member"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : "?",
                  style: TextStyle(
                    fontSize: 32,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('View Profile'),
              onTap: () {
                // Profile logic remains intact
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.workspace_premium_outlined,
                color: Colors.amber,
              ),
              title: const Text('Subscribe'),
              onTap: () {
                // Subscription logic remains intact
              },
            ),

            const Divider(),

            ExpansionTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              children: [
                SwitchListTile(
                  // Dynamic text based on current theme intact
                  title: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
                  secondary: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                  value: isDarkMode,
                  onChanged: (bool value) => themeNotifier.toggleTheme(),
                ),
                ListTile(
                  title: const Text('Audio Quality'),
                  trailing: const Text('High'),
                  onTap: () {},
                ),
              ],
            ),

            const Spacer(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                // Sign out logic remains intact
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
