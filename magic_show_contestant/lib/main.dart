import 'package:flutter/material.dart';
import 'models/app_settings.dart';
import 'screens/contestant_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MagicShowApp());
}

class MagicShowApp extends StatelessWidget {
  const MagicShowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Codemagic Magic Show',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0031EA),
        ),
        useMaterial3: true,
      ),
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    AppSettings.load().then((s) {
      if (mounted) setState(() => _settings = s);
    });
  }

  void _onSettingsSaved(AppSettings settings) {
    setState(() => _settings = settings);
    // Pop back to contestant screen if settings was pushed on top of it.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(onSaved: _onSettingsSaved),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!settings.isConfigured) {
      return SettingsScreen(onSaved: _onSettingsSaved);
    }

    return ContestantScreen(
      settings: settings,
      onOpenSettings: _openSettings,
    );
  }
}
