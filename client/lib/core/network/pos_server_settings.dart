import 'package:shared_preferences/shared_preferences.dart';

/// Tenant REST (`baseUrl` from company connect — [AuthApi]).
class PosServerSettings {
  static const legacyTenantBaseUrlKey = 'baseUrl';

  final SharedPreferences _prefs;

  PosServerSettings(this._prefs);

  static String normalizeRoot(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r':0(?=/|$)', caseSensitive: false), '');
    return s.replaceAll(RegExp(r'/$'), '');
  }

  /// Tenant REST base from prefs (`baseUrl`).
  String? get tenantApiBaseUrl {
    final raw = _prefs.getString(legacyTenantBaseUrlKey)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return normalizeRoot(raw);
  }
}
