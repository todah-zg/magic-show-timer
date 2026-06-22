import 'package:flutter/material.dart';
import '../models/app_settings.dart';

class ContestantScreen extends StatelessWidget {
  final AppSettings settings;
  final VoidCallback onOpenSettings;

  const ContestantScreen({
    super.key,
    required this.settings,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Codemagic Magic Show'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Preferences',
            onPressed: onOpenSettings,
          ),
        ],
      ),
      body: const Center(child: Text('Contestant screen — coming soon')),
    );
  }
}
