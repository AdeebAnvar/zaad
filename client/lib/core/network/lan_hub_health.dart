import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pos/core/network/local_hub_settings.dart';

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
  const LanHubWsPeerBrief({this.deviceId, this.ip, this.port});

  final String? deviceId;
  final String? ip;
  final int? port;

  factory LanHubWsPeerBrief.fromJson(Map<String, dynamic> json) {
    final portRaw = json['port'];
    return LanHubWsPeerBrief(
      deviceId: json['deviceId']?.toString(),
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
  } catch (e, st) {
    if (kDebugMode) debugPrint('[lan_hub_health] fetch failed: $e\n$st');
    return null;
  }
}

/// When MAIN has no cashier SUB listening, skipping catalog / COMPANY_SNAPSHOT avoids useless
/// outbound WS (and timeouts) while [LocalHubPrimaryInbound] stays connected (counts as 1).
class LanHeavyMirrorGate {
  LanHeavyMirrorGate._();

  static Future<bool> shouldSkipForSolitaryWsHub(LocalHubSettings hub) async {
    if (!hub.skipHeavyLanMirrorUnlessExtraWsPeers) return false;
    final wsUrl = hub.publishHubWsUrlOrLoopback;
    final healthUri = lanHubHealthUriFromStoredWsUrl(wsUrl);
    if (healthUri == null) return false;
    final summary = await fetchLanHubWsHealthSummary(healthUri);
    if (summary == null) return false;
    return summary.openSockets <= 1;
  }
}
