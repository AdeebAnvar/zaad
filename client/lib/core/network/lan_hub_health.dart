import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pos/core/debug/agent_debug_log.dart';
import 'package:pos/core/network/local_hub_settings.dart';

DateTime? _lastHealthFetchErrorLogAt;
String? _lastHealthFetchErrorKey;

/// Parsed `GET /health` subset from the MAIN Node hub (`server/src/app.js`).
class LanHubWsHealthSummary {
  const LanHubWsHealthSummary({
    required this.openSockets,
    this.peers = const <LanHubWsPeerBrief>[],
  });

  /// Count of sockets in READY/OPEN state on `/ws`.
  final int openSockets;

  /// Up to 64 OPEN peers (`deviceId` + remote IP).
  final List<LanHubWsPeerBrief> peers;
}

class LanHubWsPeerBrief {
  const LanHubWsPeerBrief({this.deviceId, this.deviceName, this.ip, this.port});

  final String? deviceId;
  final String? deviceName;
  final String? ip;
  final int? port;

  factory LanHubWsPeerBrief.fromJson(Map<String, dynamic> json) {
    final portRaw = json['port'];
    return LanHubWsPeerBrief(
      deviceId: json['deviceId']?.toString(),
      deviceName: json['deviceName']?.toString(),
      ip: json['ip']?.toString(),
      port: portRaw is num ? portRaw.toInt() : int.tryParse('$portRaw'),
    );
  }
}

/// Builds `http(s)://host:port/health` from stored `ws://…/ws`.
Uri? lanHubHealthUriFromStoredWsUrl(String wsUrlRaw) {
  final s = wsUrlRaw.trim();
  if (s.isEmpty) return null;
  final u = Uri.tryParse(s.startsWith('ws') || s.startsWith('wss') ? s : 'ws://$s');
  if (u == null || u.host.isEmpty) return null;
  final httpScheme = u.scheme.toLowerCase() == 'wss' ? 'https' : 'http';
  final port = u.hasPort ? u.port : LocalHubSettings.defaultHubWsPort;
  return Uri(scheme: httpScheme, host: u.host, port: port, path: '/health');
}

LanHubWsHealthSummary? parseLanHubHealthJson(Map<String, dynamic> decoded) {
  final wsRaw = decoded['ws'];
  if (wsRaw is! Map<String, dynamic>) return null;
  final n = wsRaw['openSockets'];
  if (n is! num) return null;
  final peersRaw = wsRaw['peers'];
  final peers = <LanHubWsPeerBrief>[];
  if (peersRaw is List<dynamic>) {
    for (final p in peersRaw) {
      if (p is Map<String, dynamic>) {
        peers.add(LanHubWsPeerBrief.fromJson(p));
      } else if (p is Map) {
        peers.add(LanHubWsPeerBrief.fromJson(Map<String, dynamic>.from(p)));
      }
    }
  }
  return LanHubWsHealthSummary(openSockets: n.toInt(), peers: peers);
}

Future<LanHubWsHealthSummary?> fetchLanHubWsHealthSummary(
  Uri healthUri, {
  Duration timeout = const Duration(seconds: 4),
}) async {
  try {
    final r = await http.get(healthUri).timeout(timeout);
    if (r.statusCode < 200 || r.statusCode >= 300) return null;
    final decoded = jsonDecode(r.body);
    if (decoded is! Map) return null;
    return parseLanHubHealthJson(Map<String, dynamic>.from(decoded));
  } catch (e) {
    if (kDebugMode) {
      final now = DateTime.now();
      final key = '${healthUri.authority}:${e.runtimeType}';
      final shouldLog = _lastHealthFetchErrorLogAt == null ||
          _lastHealthFetchErrorKey != key ||
          now.difference(_lastHealthFetchErrorLogAt!) >= const Duration(seconds: 20);
      if (shouldLog) {
        _lastHealthFetchErrorLogAt = now;
        _lastHealthFetchErrorKey = key;
        debugPrint('[lan_hub_health] fetch failed (${healthUri.authority}): $e');
      }
    }
    return null;
  }
}

/// When MAIN has no cashier SUB listening, skipping catalog / COMPANY_SNAPSHOT avoids useless
/// outbound WS (and timeouts) while [LocalHubPrimaryInbound] stays connected (counts as 1).
Future<bool> _hubHealthOk(String wsUrl, {Duration timeout = const Duration(seconds: 2)}) async {
  final healthUri = lanHubHealthUriFromStoredWsUrl(wsUrl);
  if (healthUri == null) return false;
  final summary = await fetchLanHubWsHealthSummary(healthUri, timeout: timeout);
  return summary != null;
}

/// Cached hub reachability so a dead LAN IP does not trigger a 5s WebSocket timeout per outbox row.
class LanHubReachability {
  LanHubReachability._();

  static String? _cachedPrimary;
  static String? _cachedResolved;
  static DateTime? _cachedAt;
  static const _ttl = Duration(seconds: 20);

  static void invalidate() {
    _cachedPrimary = null;
    _cachedResolved = null;
    _cachedAt = null;
  }

  /// Returns a `ws://…` URL whose `/health` responds, or `null` when none is reachable.
  static Future<String?> resolvePublishWsUrl(LocalHubSettings hub) async {
    final primary = hub.publishHubWsUrlOrLoopback.trim();
    if (primary.isEmpty) return null;

    final now = DateTime.now();
    if (_cachedPrimary == primary &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _ttl) {
      return _cachedResolved;
    }

    String? resolved;
    if (await _hubHealthOk(primary)) {
      resolved = primary;
    } else if (!hub.isHubSub &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final loopback = LocalHubSettings.defaultMainPublishHubLoopback;
      if (loopback != primary && await _hubHealthOk(loopback)) {
        if (kDebugMode) {
          debugPrint(
            '[LanHubReachability] $primary unreachable — using $loopback for MAIN publish',
          );
        }
        resolved = loopback;
      }
    }

    _cachedPrimary = primary;
    _cachedResolved = resolved;
    _cachedAt = now;
    return resolved;
  }
}

class LanHeavyMirrorGate {
  LanHeavyMirrorGate._();

  static Future<bool> shouldSkipForSolitaryWsHub(LocalHubSettings hub) async {
    if (!hub.skipHeavyLanMirrorUnlessExtraWsPeers) {
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H1',
        location: 'lan_hub_health.dart:shouldSkipForSolitaryWsHub',
        message: 'solitary_gate_off_pref',
        data: const <String, Object?>{'skip': false},
      );
      // #endregion
      return false;
    }
    final wsUrl = hub.publishHubWsUrlOrLoopback;
    final healthUri = lanHubHealthUriFromStoredWsUrl(wsUrl);
    if (healthUri == null) {
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H1',
        location: 'lan_hub_health.dart:shouldSkipForSolitaryWsHub',
        message: 'solitary_gate_no_health_uri',
        data: const <String, Object?>{},
      );
      // #endregion
      return false;
    }
    final summary = await fetchLanHubWsHealthSummary(healthUri);
    if (summary == null) {
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H1',
        location: 'lan_hub_health.dart:shouldSkipForSolitaryWsHub',
        message: 'solitary_gate_health_fetch_null',
        data: const <String, Object?>{},
      );
      // #endregion
      return false;
    }
    final skip = summary.openSockets <= 1;
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H1',
      location: 'lan_hub_health.dart:shouldSkipForSolitaryWsHub',
      message: 'solitary_gate_evaluated',
      data: <String, Object?>{
        'openSockets': summary.openSockets,
        'skipMirror': skip,
      },
    );
    // #endregion
    return skip;
  }
}
