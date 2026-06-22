import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/app_settings.dart';
import '../services/google_sheets_service.dart';
import '../services/sheets_service.dart';

enum _Phase { form, timing, thankyou }

class ContestantScreen extends StatefulWidget {
  final AppSettings settings;
  final VoidCallback onOpenSettings;

  const ContestantScreen({
    super.key,
    required this.settings,
    required this.onOpenSettings,
  });

  @override
  State<ContestantScreen> createState() => _ContestantScreenState();
}

class _ContestantScreenState extends State<ContestantScreen> {
  _Phase _phase = _Phase.form;

  // Form
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _nameError = false;
  bool _emailError = false;

  // Timer
  final _stopwatch = Stopwatch();
  Timer? _ticker;
  int _elapsedSeconds = 0;

  // Submission
  bool _submitting = false;
  String? _errorMessage;

  // Thank-you
  String _contestantName = '';
  int _countdown = 0;
  Timer? _countdownTimer;

  final SheetsService _sheets = GoogleSheetsService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _nicknameCtrl.dispose();
    _ticker?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Form ─────────────────────────────────────────────────────────────────

  bool _validateForm() {
    final nameErr = _nameCtrl.text.trim().isEmpty;
    final emailErr = _emailCtrl.text.trim().isEmpty;
    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
    });
    return !nameErr && !emailErr;
  }

  void _start() {
    if (!_validateForm()) return;
    _contestantName = _nameCtrl.text.trim();
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    setState(() {
      _phase = _Phase.timing;
      _errorMessage = null;
    });
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  Future<void> _stop() async {
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    _elapsedSeconds = _stopwatch.elapsed.inSeconds;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    await _submit();
  }

  Future<void> _retry() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    await _submit();
  }

  Future<void> _submit() async {
    try {
      await _sheets.appendRow(
        settings: widget.settings,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        nickname: _nicknameCtrl.text.trim(),
        timeSeconds: _elapsedSeconds,
      );
      if (!mounted) return;
      _showThankYou();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'Could not save your result. Please try again.';
      });
    }
  }

  // ── Thank-you ─────────────────────────────────────────────────────────────

  void _showThankYou() {
    _countdown = 8;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown <= 1) {
        t.cancel();
        _reset();
      } else {
        setState(() => _countdown--);
      }
    });
    setState(() {
      _submitting = false;
      _phase = _Phase.thankyou;
    });
  }

  void _reset() {
    _nameCtrl.clear();
    _emailCtrl.clear();
    _nicknameCtrl.clear();
    _stopwatch.reset();
    setState(() {
      _phase = _Phase.form;
      _nameError = false;
      _emailError = false;
      _errorMessage = null;
      _elapsedSeconds = 0;
      _contestantName = '';
      _countdown = 0;
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(int totalSeconds) {
    final mm = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _GradientHeader(onSettingsTap: widget.onOpenSettings),
          Expanded(
            child: switch (_phase) {
              _Phase.form => _FormView(
                  nameCtrl: _nameCtrl,
                  emailCtrl: _emailCtrl,
                  nicknameCtrl: _nicknameCtrl,
                  nameError: _nameError,
                  emailError: _emailError,
                  onStart: _start,
                  onNameChanged: (_) {
                    if (_nameError) setState(() => _nameError = false);
                  },
                  onEmailChanged: (_) {
                    if (_emailError) setState(() => _emailError = false);
                  },
                ),
              _Phase.timing => _TimerView(
                  name: _contestantName,
                  timeDisplay: _fmt(_stopwatch.elapsed.inSeconds),
                  submitting: _submitting,
                  errorMessage: _errorMessage,
                  onStop: _submitting ? null : _stop,
                  onRetry: _retry,
                ),
              _Phase.thankyou => _ThankYouView(
                  name: _contestantName,
                  timeDisplay: _fmt(_elapsedSeconds),
                  countdown: _countdown,
                ),
            },
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const _GradientHeader({required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      color: const Color(0xFF0A0A14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/codemagic_logo.svg',
            height: 42,
          ),
          Positioned(
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white24),
              tooltip: 'Admin Settings',
              onPressed: onSettingsTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController nicknameCtrl;
  final bool nameError;
  final bool emailError;
  final VoidCallback onStart;
  final void Function(String) onNameChanged;
  final void Function(String) onEmailChanged;

  const _FormView({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.nicknameCtrl,
    required this.nameError,
    required this.emailError,
    required this.onStart,
    required this.onNameChanged,
    required this.onEmailChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter your details to compete',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: const Color(0xFF0031EA),
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        errorText: nameError ? 'Required' : null,
                        border: const OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: onNameChanged,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        errorText: emailError ? 'Required' : null,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: onEmailChanged,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nicknameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nickname (optional)',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onStart(),
                    ),
                    const SizedBox(height: 40),
                    _GradientButton(label: 'START', onPressed: onStart),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerView extends StatelessWidget {
  final String name;
  final String timeDisplay;
  final bool submitting;
  final String? errorMessage;
  final VoidCallback? onStop;
  final VoidCallback onRetry;

  const _TimerView({
    required this.name,
    required this.timeDisplay,
    required this.submitting,
    this.errorMessage,
    this.onStop,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Go, $name!',
                  style: const TextStyle(
                    fontSize: 28,
                    color: Color(0xFF0031EA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      timeDisplay,
                      style: const TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.w200,
                        color: Color(0xFF00CEFF),
                        letterSpacing: -4,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: submitting
                        ? const Center(child: CircularProgressIndicator())
                        : _GradientButton(label: 'STOP', onPressed: onStop),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: onRetry,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThankYouView extends StatelessWidget {
  final String name;
  final String timeDisplay;
  final int countdown;

  const _ThankYouView({
    required this.name,
    required this.timeDisplay,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Amazing, $name!',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0031EA),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your time',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      timeDisplay,
                      style: const TextStyle(
                        fontSize: 96,
                        fontWeight: FontWeight.w200,
                        color: Color(0xFF00CEFF),
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your result has been recorded!',
                    style: TextStyle(fontSize: 22, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Next contestant in $countdown seconds…',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _GradientButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 80,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFFEC0C43), Color(0xFFFF9100)],
                )
              : null,
          color: enabled ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.grey[500],
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
