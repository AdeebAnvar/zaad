import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_mode.dart';
import '../config/pos_app_runtime_config.dart';

/// LAN hub vs tenant REST (`baseUrl` from [AuthApi]). Hub HTTP uses [hubRoot]; WebSocket uses [enablesLanWebSocket].
class PosServerSettings {
  static const _keyHubBaseUrl = 'pos_server_base_url';

  /// Dio tenant API root after company connect — not used for Node `/orders` or `/ws`.
  static const legacyTenantBaseUrlKey = 'baseUrl';

  static const String _dartDefineHub =
      String.fromEnvironment('POS_SERVER_BASE_URL');

  final SharedPreferences _prefs;

  PosServerSettings(this._prefs);

  static Future<PosServerSettings> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PosServerSettings(prefs);
  }

  static String normalizeRoot(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r':0(?=/|$)', caseSensitive: false), '');
    return s.replaceAll(RegExp(r'/$'), '');
  }

  /// Tenant REST base from prefs.
  String? get tenantApiBaseUrl {
    final raw = _prefs.getString(legacyTenantBaseUrlKey)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return normalizeRoot(raw);
  }

  String? _lanHubCandidate() {
    var raw = _prefs.getString(PosAppRuntimeConfig.keyLocalBaseUrl)?.trim();
    if (raw == null || raw.isEmpty) raw = _prefs.getString(_keyHubBaseUrl)?.trim();
    if (raw == null || raw.isEmpty) {
      raw = _dartDefineHub.trim().isEmpty ? null : _dartDefineHub.trim();
    }
    if (raw == null || raw.isEmpty) return null;
    return normalizeRoot(raw);
  }

  AppMode _readMode() =>
      parseAppMode(_prefs.getString(PosAppRuntimeConfig.keyMode)) ?? AppMode.cloud;

  /// Hub HTTP root for [PosApiService]. In [AppMode.cloud], omitted unless URL configured **and**
  /// `cloud_allow_lan_hub_orders` is true (default).
  String? get hubRoot {
    final mode = _readMode();
    final lan = _lanHubCandidate();
    if (mode == AppMode.local) return lan;
    final allow =
        _prefs.getBool(PosAppRuntimeConfig.keyCloudAllowLanHubOrders) ?? true;
    if (!allow) return null;
    return lan;
  }

  /// WebSocket + startup hydrate: needs a non-empty LAN hub URL.
  ///
  /// Matches [hubRoot] availability: **[AppMode.local]** always; in **[AppMode.cloud]**
  /// only when [PosAppRuntimeConfig.keyCloudAllowLanHubOrders] is true — otherwise HTTP hub
  /// could work but `/ws` would stay off and order logs would not refresh live.
  bool get enablesLanWebSocket {
    final lan = _lanHubCandidate();
    if (lan == null || lan.isEmpty) return false;
    final mode = _readMode();
    if (mode == AppMode.local) return true;
    if (mode == AppMode.cloud) {
      return _prefs.getBool(PosAppRuntimeConfig.keyCloudAllowLanHubOrders) ?? true;
    }
    return false;
  }

  /// Same as [hubRoot] (compat).
  String? get baseUrl => hubRoot;

  /// Persists hub URL to both `pos_server_base_url` and `local_base_url`.
  Future<void> setBaseUrl(String value) async {
    final n = normalizeRoot(value);
    await _prefs.setString(_keyHubBaseUrl, n);
    await _prefs.setString(PosAppRuntimeConfig.keyLocalBaseUrl, n);
  }

  Future<void> clear() async {
    await _prefs.remove(_keyHubBaseUrl);
    await _prefs.remove(PosAppRuntimeConfig.keyLocalBaseUrl);
  }
}
