import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final String credentialsPath;
  final String sheetId;

  const AppSettings({required this.credentialsPath, required this.sheetId});

  bool get isConfigured => credentialsPath.isNotEmpty && sheetId.isNotEmpty;

  static const _kCredentials = 'credentials_path';
  static const _kSheetId = 'sheet_id';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      credentialsPath: prefs.getString(_kCredentials) ?? '',
      sheetId: prefs.getString(_kSheetId) ?? '',
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kCredentials, credentialsPath),
      prefs.setString(_kSheetId, sheetId),
    ]);
  }

  AppSettings copyWith({String? credentialsPath, String? sheetId}) {
    return AppSettings(
      credentialsPath: credentialsPath ?? this.credentialsPath,
      sheetId: sheetId ?? this.sheetId,
    );
  }
}
