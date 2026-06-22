import 'dart:convert';
import 'dart:io';

import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

import '../models/app_settings.dart';
import 'sheets_service.dart';

class GoogleSheetsService implements SheetsService {
  @override
  Future<void> appendRow({
    required AppSettings settings,
    required String name,
    required String email,
    required String nickname,
    required int timeSeconds,
  }) async {
    final credJson = jsonDecode(
      await File(settings.credentialsPath).readAsString(),
    ) as Map<String, dynamic>;

    final credentials = ServiceAccountCredentials.fromJson(credJson);

    // clientViaServiceAccount handles the JWT exchange internally.
    // A new client per submission is intentional — token refresh logic
    // would be disproportionate for a booth app with infrequent writes.
    final client = await clientViaServiceAccount(
      credentials,
      [SheetsApi.spreadsheetsScope],
    );

    try {
      final api = SheetsApi(client);
      await api.spreadsheets.values.append(
        ValueRange(values: [[name, email, nickname, timeSeconds]]),
        settings.sheetId,
        'A:E', // range determines which sheet tab; defaults to the first tab
        valueInputOption: 'RAW', // prevents '=formula' injection from user input
        insertDataOption: 'INSERT_ROWS',
      );
    } finally {
      client.close();
    }
  }
}
