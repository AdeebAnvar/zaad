import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app flags (SharedPreferences).
class PosAppRuntimeConfig {
  PosAppRuntimeConfig(this._prefs);

  final SharedPreferences _prefs;

  /// Set after one successful setup/connect path (migration anchor).
  static const String keySetupCompleted = 'pos_setup_completed';

  bool get isSetupCompleted => _prefs.getBool(keySetupCompleted) ?? false;

  Future<void> markSetupCompleted() => _prefs.setBool(keySetupCompleted, true);

  /// First-run setup screen is not used; startup goes to login.
  bool needsFirstRunSetup() => false;

  void logDiagnostics() {
    final tenant = _prefs.getString('baseUrl');
    debugPrint('[POS] TENANT BASE URL (cloud sync): ${tenant ?? '(unset)'}');
  }
}
