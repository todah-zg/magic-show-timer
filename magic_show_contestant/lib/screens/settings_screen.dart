import 'package:flutter/material.dart';
import '../models/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  final void Function(AppSettings) onSaved;

  const SettingsScreen({super.key, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings — coming soon')),
    );
  }
}
