import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final String credentialsJson;
  final String sheetId;

  const AppSettings({required this.credentialsJson, required this.sheetId});

  bool get isConfigured => credentialsJson.isNotEmpty && sheetId.isNotEmpty;

  static const _kCredentials = 'credentials_json';
  static const _kSheetId = 'sheet_id';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      credentialsJson: prefs.getString(_kCredentials) ?? '',
      sheetId: prefs.getString(_kSheetId) ?? '',
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kCredentials, credentialsJson),
      prefs.setString(_kSheetId, sheetId),
    ]);
  }

  AppSettings copyWith({String? credentialsJson, String? sheetId}) {
    return AppSettings(
      credentialsJson: credentialsJson ?? this.credentialsJson,
      sheetId: sheetId ?? this.sheetId,
    );
  }
}
