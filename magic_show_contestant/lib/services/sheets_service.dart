import '../models/app_settings.dart';

abstract class SheetsService {
  Future<void> appendRow({
    required AppSettings settings,
    required String name,
    required String email,
    required String nickname,
    required int timeSeconds,
  });
}

/// Stub used until GoogleSheetsService is wired in the next step.
class StubSheetsService implements SheetsService {
  @override
  Future<void> appendRow({
    required AppSettings settings,
    required String name,
    required String email,
    required String nickname,
    required int timeSeconds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
  }
}
