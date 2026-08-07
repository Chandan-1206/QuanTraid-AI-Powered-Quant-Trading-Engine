import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Toggle app theme'),
              value: provider.isDarkMode,
              onChanged: (val) {
                provider.toggleTheme();
              },
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Risk Preference'),
              subtitle: const Text('Conservative / Moderate / Aggressive'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Future expansion
              },
            ),
          ),
        ],
      ),
    );
  }
}
