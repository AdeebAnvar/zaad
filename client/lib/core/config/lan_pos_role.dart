/// Role of this Flutter POS when using the LAN Node hub (multi-terminal shop).
///
/// **Cloud pull/push** is performed by the **Node process** on the main PC (`server/` +
/// `cloud_sync`), not by satellite Flutter apps. Satellites must never call tenant
/// `pull_records` / `push_records` directly.
enum LanPosRole {
  /// Primary machine (typically where Node runs). May use Cloud mode or coordinate hub.
  hubHost,

  /// Secondary terminal: orders go to the hub over LAN; no direct tenant sync API.
  satellite,
}

extension LanPosRoleX on LanPosRole {
  String get storageValue => name;
}

/// Parses persisted `pos_lan_pos_role`.
LanPosRole? parseLanPosRole(String? raw) {
  final s = raw?.trim().toLowerCase();
  if (s == null || s.isEmpty) return null;
  for (final r in LanPosRole.values) {
    if (r.name == s) return r;
  }
  return null;
}
