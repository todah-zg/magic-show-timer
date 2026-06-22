import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings? initial;
  final void Function(AppSettings) onSaved;

  const SettingsScreen({super.key, this.initial, required this.onSaved});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _credentialsCtrl;
  late final TextEditingController _sheetIdCtrl;
  bool _credentialsError = false;
  bool _sheetIdError = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _credentialsCtrl =
        TextEditingController(text: widget.initial?.credentialsPath ?? '');
    _sheetIdCtrl =
        TextEditingController(text: widget.initial?.sheetId ?? '');
  }

  @override
  void dispose() {
    _credentialsCtrl.dispose();
    _sheetIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCredentials() async {
    // Must unfocus before opening NSOpenPanel — otherwise Flutter loses
    // pointer event routing and the window becomes unresponsive.
    FocusScope.of(context).unfocus();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Select service account credentials JSON',
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _credentialsCtrl.text = result.files.single.path!;
        _credentialsError = false;
      });
    }
  }

  bool _validate() {
    final credErr = _credentialsCtrl.text.trim().isEmpty;
    final sheetErr = _sheetIdCtrl.text.trim().isEmpty;
    setState(() {
      _credentialsError = credErr;
      _sheetIdError = sheetErr;
    });
    return !credErr && !sheetErr;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final settings = AppSettings(
        credentialsPath: _credentialsCtrl.text.trim(),
        sheetId: _sheetIdCtrl.text.trim(),
      );
      await settings.save();
      widget.onSaved(settings);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Settings')),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                Text(
                  'Google Sheets Configuration',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                _CredentialsField(
                  controller: _credentialsCtrl,
                  hasError: _credentialsError,
                  onBrowse: _pickCredentials,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sheetIdCtrl,
                  decoration: InputDecoration(
                    labelText: 'Google Sheet ID',
                    helperText: 'From the sheet URL: /d/{SHEET_ID}/edit',
                    errorText: _sheetIdError ? 'Required' : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    if (_sheetIdError) setState(() => _sheetIdError = false);
                  },
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CredentialsField extends StatelessWidget {
  final TextEditingController controller;
  final bool hasError;
  final VoidCallback onBrowse;

  const _CredentialsField({
    required this.controller,
    required this.hasError,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Service account credentials (JSON)',
              errorText: hasError ? 'Required' : null,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: OutlinedButton(
            onPressed: onBrowse,
            child: const Text('Browse…'),
          ),
        ),
      ],
    );
  }
}
