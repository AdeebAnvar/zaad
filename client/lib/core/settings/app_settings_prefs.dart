import 'package:shared_preferences/shared_preferences.dart';

/// Local POS preferences (not synced).
class AppSettingsPrefs {
  AppSettingsPrefs._();

  static const _kDineInSeatHandling = 'dine_in_seat_handling_enabled';
  static const _kLastManualSyncAt = 'last_manual_sync_at';

  /// Dine-in uses floor+table routing only (no per-seat allocation or move-seat).
  static Future<bool> getDineInSeatHandlingEnabled() async => false;

  static Future<void> setDineInSeatHandlingEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDineInSeatHandling, value);
  }

  static Future<void> setLastManualSyncAt(DateTime when) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLastManualSyncAt, when.toIso8601String());
  }

  static Future<DateTime?> getLastManualSyncAt() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kLastManualSyncAt);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
