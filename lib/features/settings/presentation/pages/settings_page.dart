import 'package:flutter/material.dart';
import 'package:jhonny/features/settings/presentation/widgets/language_selector.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Selection Section
            Text(
              'Language & Region',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const LanguageSelector(),

            const SizedBox(height: 24),

            // Add more settings sections here as needed
            Text(
              'Other Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Card(
              child: ListTile(
                leading: const Icon(Icons.accessibility),
                title: const Text('Accessibility'),
                subtitle: const Text('Customize accessibility features'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to accessibility settings
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
