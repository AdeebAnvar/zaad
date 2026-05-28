import 'dart:io' show Platform;

import 'package:pos/core/network/lan_hub_health.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LAN MAIN WebSocket hub (SUB terminals only; MAIN runs Node.js + SQLite).
class LocalHubSettings {
  LocalHubSettings(this._prefs);

  final SharedPreferences _prefs;

  static const wsUrlKey = 'pos_local_hub_ws_url';

  /// When MAIN has no saved hub URL, assume Node listens on this machine (Flutter POS + Node on same PC).
  ///
  /// SUB terminals must **always** set [wsUrlKey] to the MAIN PC LAN IP (`ws://192.168.x.x:3001/ws`).
  static const defaultMainPublishHubLoopback = 'ws://127.0.0.1:3001/ws';

  static const defaultHubWsPort = 3001;
  static const defaultHubWsPath = '/ws';

  /// Stable URL from user IP/host (`192.168.1.10`) or a pasted `ws://…` URI.
  static String canonicalHubWsUrl(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return '';

    final parsed = raw.contains('://') ? Uri.tryParse(raw) : Uri.tryParse('ws://$raw');
    if (parsed == null || parsed.host.isEmpty) return '';

    final schemeLower = parsed.scheme.toLowerCase();
    final scheme = schemeLower == 'wss' ? 'wss' : 'ws';
    final port = parsed.hasPort ? parsed.port : defaultHubWsPort;
    var path = parsed.path.isEmpty || parsed.path == '/' ? defaultHubWsPath : parsed.path;
    if (!path.startsWith('/')) path = '/$path';

    return '$scheme://${parsed.host}:$port$path';
  }

  /// Shown in the LAN setup IP field — host part of saved [wsUrlKey], if recognizable.
  static String hostFieldFromStoredWsUrl(String? stored) {
    final s = stored?.trim();
    if (s == null || s.isEmpty) return '';
    final u = Uri.tryParse(s.startsWith('ws') || s.startsWith('wss') ? s : 'ws://$s');
    if (u == null || u.host.isEmpty) return '';
    return u.host;
  }

  /// `hub_sub` when this Flutter acts as SUB (queues events to MAIN; no direct cloud mutations via hub).
  static const roleKey = 'pos_local_role';

  /// Stable device id persisted once (per installation).
  static const deviceIdKey = 'pos_installation_device_uuid';

  static const shadowCartKey = 'pos_lan_shadow_cart_id';

  /// MAIN + SUB: first successful MAIN login sets this; only matching [UserModel.branchId] may log in.
  static const terminalBranchIdKey = 'pos_terminal_branch_id';

  /// Millis; last applied journal watermark from SYNC_RESPONSE / inbound events ([event_journal.effective_ms] on MAIN).
  static const lastJournalMsKey = 'pos_hub_last_journal_ms';

  /// MAIN-only: after a successful tenant catalog pull, push items/categories (+ images over WS).
  /// SUB terminals never set this flag.
  static const publishCatalogAfterPullKey = 'pos_main_publish_catalog_to_hub';

  /// Prefer this for static contexts (e.g. [Dio]) before GetIt is ready.
  static bool readIsHubSub(SharedPreferences prefs) => (prefs.getString(roleKey)?.trim().toLowerCase() == 'hub_sub');

  /// MAIN: when true and hub `GET /health` reports [`ws.openSockets`] ≤ 1, skip heavy LAN broadcasts
  /// (`HubCatalogLanPublisher`, `HubCompanySnapshotPublisher`) so idle MAIN does not open push sockets.
  static const skipHeavyLanMirrorUnlessExtraWsPeersKey = 'pos_hub_skip_mirror_if_solitary_ws';

  /// Tenant pull/push REST [SyncApi] / [AuthRepository] connect must not run on SUB.
  bool get blocksTenantCloudRest => isHubSub;

  /// MAIN: defaults on so catalog stays live on SUBs; SUB always false (ignored).
  bool get publishesCatalogAfterTenantPull => isHubSub ? false : (_prefs.getBool(publishCatalogAfterPullKey) ?? true);

  Future<void> setPublishesCatalogAfterTenantPull(bool value) => _prefs.setBool(publishCatalogAfterPullKey, value);

  bool get skipHeavyLanMirrorUnlessExtraWsPeers =>
      !isHubSub && (_prefs.getBool(skipHeavyLanMirrorUnlessExtraWsPeersKey) ?? false);

  Future<void> setSkipHeavyLanMirrorUnlessExtraWsPeers(bool value) =>
      _prefs.setBool(skipHeavyLanMirrorUnlessExtraWsPeersKey, value);

  String? get hubWsUrl => _prefs.getString(wsUrlKey)?.trim();

  /// Desktop MAIN: loopback when hub URL unset. Mobile has no local Node — URL must be set explicitly.
  static bool get _defaultLoopbackWhenHubUrlUnset =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  /// MAIN (non-SUB): WebSocket URL used to **send** snapshots / API mirrors to Node.
  /// Falls back to [defaultMainPublishHubLoopback] on desktop when prefs URL is unset.
  /// Returns empty string on SUB (`hubWsUrl` must be set explicitly) and on mobile until configured.
  String get publishHubWsUrlOrLoopback {
    if (isHubSub) return hubWsUrl ?? '';
    final u = hubWsUrl;
    if (u != null && u.isNotEmpty) return u;
    return _defaultLoopbackWhenHubUrlUnset ? LocalHubSettings.defaultMainPublishHubLoopback : '';
  }

  Future<void> setHubWsUrl(String? url) async {
    LanHubReachability.invalidate();
    if (url == null || url.trim().isEmpty) {
      await _prefs.remove(wsUrlKey);
    } else {
      await _prefs.setString(wsUrlKey, url.trim());
    }
  }

  bool get isHubSub => (_prefs.getString(roleKey)?.trim().toLowerCase() == 'hub_sub');

  Future<void> setRoleHubSub(bool enabled) => enabled ? _prefs.setString(roleKey, 'hub_sub') : _prefs.remove(roleKey);

  int get lastJournalMs => _prefs.getInt(lastJournalMsKey) ?? 0;

  Future<void> saveLastJournalMs(int ms) => ms <= 0 ? Future.value() : _prefs.setInt(lastJournalMsKey, ms);

  String requireDeviceId() {
    final existing = _prefs.getString(deviceIdKey);
    if (existing != null && existing.trim().isNotEmpty) return existing.trim();
    throw StateError(
      '[LocalHub] device id unset — coordinator must initialize it first.',
    );
  }

  Future<String> resolveOrAllocateDeviceId(String Function() allocator) async {
    var existing = _prefs.getString(deviceIdKey);
    if (existing != null && existing.trim().isNotEmpty) return existing.trim();
    existing = allocator();
    await _prefs.setString(deviceIdKey, existing);
    return existing;
  }

  int? shadowCartRowIdOrNull() {
    final v = _prefs.getInt(shadowCartKey);
    if (v != null && v > 0) return v;
    return null;
  }

  Future<void> cacheShadowCartId(int id) => _prefs.setInt(shadowCartKey, id);

  int? get terminalBranchId {
    final v = _prefs.getInt(terminalBranchIdKey);
    if (v != null && v > 0) return v;
    return null;
  }

  Future<void> setTerminalBranchId(int branchId) =>
      _prefs.setInt(terminalBranchIdKey, branchId);

  Future<void> clearTerminalBranchId() => _prefs.remove(terminalBranchIdKey);
}
