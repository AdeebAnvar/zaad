import 'package:shared_preferences/shared_preferences.dart';

/// Local POS preferences (not synced).
class AppSettingsPrefs {
  AppSettingsPrefs._();

  static const _kDineInSeatHandling = 'dine_in_seat_handling_enabled';
  static const _kLastManualSyncAt = 'last_manual_sync_at';

  /// When true (default), Dine In uses chair assignment and caps orders by seat count.
  /// When false, tables accept multiple orders without per-seat allocation.
  static Future<bool> getDineInSeatHandlingEnabled() async {
    return false;
  }

  static Future<void> setDineInSeatHandlingEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDineInSeatHandling, false);
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
