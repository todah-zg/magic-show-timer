import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        builder: (_) => SettingsScreen(
          initial: _settings,
          onSaved: _onSettingsSaved,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

    final Widget screen;
    if (settings == null) {
      screen = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (!settings.isConfigured) {
      screen = SettingsScreen(onSaved: _onSettingsSaved);
    } else {
      screen = ContestantScreen(
        settings: settings,
        onOpenSettings: _openSettings,
      );
    }

    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'Magic Show',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Preferences…',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.comma,
                    meta: true,
                  ),
                  // Disabled when unconfigured — user is already on settings.
                  onSelected:
                      settings?.isConfigured == true ? _openSettings : null,
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                const PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.quit,
                ),
              ],
            ),
          ],
        ),
      ],
      child: screen,
    );
  }
}
