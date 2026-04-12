import 'package:shared_preferences/shared_preferences.dart';

/// Local POS preferences (not synced).
class AppSettingsPrefs {
  AppSettingsPrefs._();

  static const _kDineInSeatHandling = 'dine_in_seat_handling_enabled';

  /// When true (default), Dine In uses chair assignment and caps orders by seat count.
  /// When false, tables accept multiple orders without per-seat allocation.
  static Future<bool> getDineInSeatHandlingEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kDineInSeatHandling) ?? true;
  }

  static Future<void> setDineInSeatHandlingEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDineInSeatHandling, value);
  }
}
