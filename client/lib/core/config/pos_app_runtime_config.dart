import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_mode.dart';
import 'lan_pos_role.dart';

/// Persisted multi-mode POS configuration (SharedPreferences).
///
/// Does **not** replace [PosHubAuth] secure token storage — hub Bearer stays in secure storage.
class PosAppRuntimeConfig {
  PosAppRuntimeConfig(this._prefs);

  final SharedPreferences _prefs;

  static const String keyMode = 'pos_app_mode';

  /// [LanPosRole] — main hub PC vs sub terminal (see [lanPosRole]).
  static const String keyLanPosRole = 'pos_lan_pos_role';

  /// LAN Node root (`http://host:3000`) after resolve or manual save; mirrored to `pos_server_base_url`.
  static const String keyLocalBaseUrl = 'local_base_url';

  /// Optional `http://<ip>:3000` used when [preferredHost] does not resolve.
  static const String keyFallbackBaseUrl = 'local_hub_fallback_base_url';

  /// Primary LAN URL from QR / admin (tried before fixed hostname in local hub resolve).
  static const String keyPrimaryLanBaseUrl = 'local_hub_primary_base_url';

  /// Set after user completes [SetupScreen] once (first-run / migration anchor).
  static const String keySetupCompleted = 'pos_setup_completed';

  /// When [AppMode.cloud], still allow [PosApiService] / hub checkout if a LAN URL is configured (default **true** — migration).
  static const String keyCloudAllowLanHubOrders = 'cloud_allow_lan_hub_orders';

  /// Zero-config LAN hostname (router DNS / mDNS).
  static const String preferredHost = 'POS-SERVER';

  static const int preferredPort = 3000;

  /// Effective mode; missing key → [AppMode.cloud] (existing installs).
  AppMode get mode => parseAppMode(_prefs.getString(keyMode)) ?? AppMode.cloud;

  Future<void> setMode(AppMode value) => _prefs.setString(keyMode, value.storageValue);

  String? get localBaseUrl {
    final v = _prefs.getString(keyLocalBaseUrl)?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  /// Prefs hub snapshot for QR `fallback_ip` (alias for “getBaseUrl” style APIs).
  String? get connectionHubUrlSync {
    final l = localBaseUrl;
    if (l != null && l.isNotEmpty) return l;
    final h = _prefs.getString('pos_server_base_url')?.trim();
    if (h == null || h.isEmpty) return null;
    return h;
  }

  Future<void> setLocalBaseUrl(String normalizedRoot) =>
      _prefs.setString(keyLocalBaseUrl, normalizedRoot);

  String? get fallbackBaseUrl {
    final v = _prefs.getString(keyFallbackBaseUrl)?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  Future<void> setFallbackBaseUrl(String? normalizedRoot) async {
    if (normalizedRoot == null || normalizedRoot.trim().isEmpty) {
      await _prefs.remove(keyFallbackBaseUrl);
      return;
    }
    await _prefs.setString(keyFallbackBaseUrl, normalizedRoot.trim());
  }

  Future<void> clearFallbackBaseUrl() => _prefs.remove(keyFallbackBaseUrl);

  /// Alias for QR / scan flows ([setFallbackBaseUrl]).
  Future<void> setFallbackUrl(String? normalizedRoot) =>
      setFallbackBaseUrl(normalizedRoot);

  String? get primaryLanBaseUrl {
    final v = _prefs.getString(keyPrimaryLanBaseUrl)?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  Future<void> setPrimaryLanBaseUrl(String? normalizedRoot) async {
    if (normalizedRoot == null || normalizedRoot.trim().isEmpty) {
      await _prefs.remove(keyPrimaryLanBaseUrl);
      return;
    }
    await _prefs.setString(keyPrimaryLanBaseUrl, normalizedRoot.trim());
  }

  Future<void> clearPrimaryLanBaseUrl() => _prefs.remove(keyPrimaryLanBaseUrl);

  bool get isSetupCompleted => _prefs.getBool(keySetupCompleted) ?? false;

  Future<void> markSetupCompleted() => _prefs.setBool(keySetupCompleted, true);

  bool get cloudAllowsLanHubOrders =>
      _prefs.getBool(keyCloudAllowLanHubOrders) ?? true;

  Future<void> setCloudAllowLanHubOrders(bool value) =>
      _prefs.setBool(keyCloudAllowLanHubOrders, value);

  bool get isCloud => mode == AppMode.cloud;
  bool get isLocal => mode == AppMode.local;

  /// Missing / unknown → [LanPosRole.hubHost] (legacy installs).
  LanPosRole get lanPosRole =>
      parseLanPosRole(_prefs.getString(keyLanPosRole)) ?? LanPosRole.hubHost;

  Future<void> setLanPosRole(LanPosRole value) =>
      _prefs.setString(keyLanPosRole, value.storageValue);

  bool get isLanSatellite => lanPosRole == LanPosRole.satellite;

  /// Legacy: first-run used to force [SetupScreen]. Deployment is optional — users open
  /// **Settings → Deployment** (or login long-press) to choose cloud vs LAN / QR; startup always goes to login.
  bool needsFirstRunSetup() => false;

  /// Startup diagnostics (PART 9).
  void logDiagnostics({String? tenantBaseHint}) {
    final lan = localBaseUrl ?? _prefs.getString('pos_server_base_url');
    final tenant = tenantBaseHint ?? _prefs.getString('baseUrl');
    final fb = fallbackBaseUrl;
    debugPrint('[POS] MODE: ${mode.name.toUpperCase()}');
    debugPrint('[POS] TENANT BASE URL (cloud sync): ${tenant ?? '(unset)'}');
    debugPrint('[POS] LAN HUB URL: ${lan ?? '(unset)'}');
    debugPrint('[POS] PRIMARY LAN (QR/custom): ${primaryLanBaseUrl ?? '(unset)'}');
    debugPrint('[POS] FALLBACK LAN URL: ${fb ?? '(unset)'}');
    debugPrint('[POS] preferred LAN: http://$preferredHost:$preferredPort');
    debugPrint('[POS] cloud_allow_lan_hub_orders: $cloudAllowsLanHubOrders');
    debugPrint('[POS] LAN device role: ${lanPosRole.name}');
  }
}
