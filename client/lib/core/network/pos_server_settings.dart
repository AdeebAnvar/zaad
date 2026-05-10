import 'package:shared_preferences/shared_preferences.dart';

/// Tenant REST (`baseUrl` from company connect — [AuthApi]).
class PosServerSettings {
  static const legacyTenantBaseUrlKey = 'baseUrl';
  static const tenantConnectLastAppIdKey = 'tenant_connect_last_app_id';

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

  /// Last tenant app id/code typed in “Connect to server” (for prefilling the dialog).
  String? get lastTenantConnectAppId {
    final raw = _prefs.getString(tenantConnectLastAppIdKey)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  Future<void> setLastTenantConnectAppId(String code) async {
    final t = code.trim();
    if (t.isEmpty) return;
    await _prefs.setString(tenantConnectLastAppIdKey, t);
  }
}
