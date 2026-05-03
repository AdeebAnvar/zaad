/// Runtime POS deployment mode — drives sync, WebSocket, and hub URL semantics.
enum AppMode {
  /// Tenant REST + Drift cache; pull/push via [SyncApi]; optional LAN hub HTTP when URL + flag set.
  cloud,

  /// LAN Node hub for orders. Flutter does **not** call tenant pull/push — Node handles cloud.
  /// Mark sub terminals as **satellite** in deployment setup so they never call cloud APIs.
  local,
}

extension AppModeX on AppMode {
  String get storageValue => name;
}

/// Parses persisted `pos_app_mode` value.
AppMode? parseAppMode(String? raw) {
  final s = raw?.trim().toLowerCase();
  if (s == null || s.isEmpty) return null;
  for (final m in AppMode.values) {
    if (m.name == s) return m;
  }
  return null;
}
