import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pos/core/config/app_mode.dart';
import 'package:pos/core/config/pos_app_runtime_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pos_server_settings.dart';

bool _isLikelyUnreachableHub(Object e) {
  final t = e.toString();
  return t.contains('SocketException') ||
      t.contains('refused') ||
      t.contains('Connection reset') ||
      t.contains('Network is unreachable') ||
      t.contains('Host is unreachable');
}

/// Resolves LAN hub URL (hostname-first) and reads tenant REST base from prefs.
///
/// Cloud tenant URL is set by connect/login (`baseUrl`); this class does not call suite APIs.
class BaseUrlResolver {
  BaseUrlResolver(
    this._prefs,
    this._runtime, {
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final SharedPreferences _prefs;
  final PosAppRuntimeConfig _runtime;
  final http.Client _http;

  /// Primary LAN hostname (mDNS / DNS — configure router or hosts).
  static String hostUrlFromPreferred() {
    final root =
        'http://${PosAppRuntimeConfig.preferredHost}:${PosAppRuntimeConfig.preferredPort}';
    return PosServerSettings.normalizeRoot(root);
  }

  /// Same normalization as manual setup / QR (`http://` default, port [PosAppRuntimeConfig.preferredPort]).
  static String? normalizeLanHubUrl(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'http://$s';
    }
    final u = Uri.tryParse(s);
    if (u == null || u.host.isEmpty) return null;
    if (!u.hasPort || u.port == 0) {
      return PosServerSettings.normalizeRoot(
        '${u.scheme}://${u.host}:${PosAppRuntimeConfig.preferredPort}',
      );
    }
    return PosServerSettings.normalizeRoot(s);
  }

  /// Dio / `SyncApi` root after company connect (`baseUrl` key).
  String? tenantRestBaseSync() {
    final raw =
        _prefs.getString(PosServerSettings.legacyTenantBaseUrlKey)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return PosServerSettings.normalizeRoot(raw);
  }

  /// Raw LAN hub string from prefs / dart-define (sync snapshot; prefer [resolveLocalBaseUrl] in LOCAL mode).
  String? lanHubCandidateSync() {
    var raw = _prefs.getString(PosAppRuntimeConfig.keyLocalBaseUrl)?.trim();
    if (raw == null || raw.isEmpty) {
      raw = _prefs.getString('pos_server_base_url')?.trim();
    }
    if (raw == null || raw.isEmpty) {
      const d = String.fromEnvironment('POS_SERVER_BASE_URL');
      raw = d.trim().isEmpty ? null : d.trim();
    }
    if (raw == null || raw.isEmpty) return null;
    return PosServerSettings.normalizeRoot(raw);
  }

  /// Hub HTTP base for optional cloud+LAN checkout (prefs only).
  String? hubHttpBaseSync() {
    final candidate = lanHubCandidateSync();
    if (_runtime.mode == AppMode.local) return candidate;
    if (!_runtime.cloudAllowsLanHubOrders) return null;
    return candidate;
  }

  String? websocketHubBaseSync() {
    if (!_runtime.isLocal) return null;
    return lanHubCandidateSync();
  }

  static const Duration _healthTimeout = Duration(seconds: 5);

  Future<bool> healthOk(String base) async {
    final root = PosServerSettings.normalizeRoot(base);
    final uri = Uri.parse(root).resolve('/health');
    try {
      final res = await _http.get(uri).timeout(_healthTimeout);
      final ct = res.headers['content-type']?.toLowerCase() ?? '';
      final jsonCt = ct.contains('application/json');
      if (res.statusCode != 200 || !jsonCt) {
        if (kDebugMode) {
          debugPrint('[POS] health FAIL $uri → ${res.statusCode}, ct=$ct');
        }
        return false;
      }
      try {
        final dec = jsonDecode(res.body);
        if (dec is Map && dec['ok'] == true) {
          if (kDebugMode) debugPrint('[POS] health OK $uri');
          return true;
        }
      } catch (_) {}
      if (kDebugMode) {
        debugPrint('[POS] health FAIL $uri → JSON without ok:true');
      }
      return false;
    } catch (e, st) {
      if (kDebugMode) {
        if (e is TimeoutException) {
          debugPrint(
            '[POS] health TIMEOUT $uri after ${_healthTimeout.inSeconds}s (hub down, wrong host, or slow LAN)',
          );
        } else if (_isLikelyUnreachableHub(e)) {
          debugPrint(
            '[POS] health UNREACHABLE $uri — hub not listening yet, wrong IP, or blocked (no stack)',
          );
        } else {
          debugPrint('[POS] health ERROR $uri → $e\n$st');
        }
      }
      return false;
    }
  }

  /// Tries saved hub URL first (fast when `pos-server` does not resolve), then QR primary,
  /// then `http://POS-SERVER:{port}`, then [PosAppRuntimeConfig.fallbackBaseUrl].
  Future<String> resolveLocalBaseUrl() async {
    final candidates = <String>[];
    void addUnique(String? s) {
      if (s == null || s.isEmpty) return;
      final n = PosServerSettings.normalizeRoot(s);
      if (!candidates.contains(n)) candidates.add(n);
    }

    addUnique(lanHubCandidateSync());
    addUnique(_runtime.primaryLanBaseUrl);
    addUnique(hostUrlFromPreferred());

    for (final url in candidates) {
      if (await healthOk(url)) return url;
    }

    final fallback = _runtime.fallbackBaseUrl;
    if (fallback != null &&
        fallback.isNotEmpty &&
        await healthOk(fallback)) {
      return PosServerSettings.normalizeRoot(fallback);
    }

    // Hub may be starting, or /health failed while :3000 will work a moment later — trust prefs.
    final saved = lanHubCandidateSync();
    if (saved != null && saved.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[POS] health: all probes failed — keeping saved hub URL (retry when online): $saved',
        );
      }
      return saved;
    }

    if (fallback != null && fallback.isNotEmpty) {
      final n = PosServerSettings.normalizeRoot(fallback);
      if (kDebugMode) {
        debugPrint(
          '[POS] health: all probes failed — using configured fallback: $n',
        );
      }
      return n;
    }

    throw Exception(
      'Local POS server not reachable — set hub IP in Settings or start the Node server on port 3000',
    );
  }

  /// LOCAL: probe network for hub. CLOUD: no network I/O; returns null (use prefs / tenant APIs elsewhere).
  Future<String?> resolvePrimaryHubAsync() async {
    if (!_runtime.isLocal) return null;
    return resolveLocalBaseUrl();
  }
}
