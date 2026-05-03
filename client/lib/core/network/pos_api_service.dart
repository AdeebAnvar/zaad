import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pos/core/config/pos_app_runtime_config.dart';

import 'pos_hub_auth.dart';
import 'pos_server_settings.dart';

/// Thrown when the hub returns a non-success HTTP status (used for cart / checkout UX).
class PosHubHttpException implements Exception {
  PosHubHttpException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// HTTP helper for the Node hub (`Authorization: Bearer`).
class PosApiService {
  PosApiService({
    required PosServerSettings settings,
    required PosHubAuth auth,
    required PosAppRuntimeConfig runtime,
    http.Client? httpClient,
    int maxAttempts = 3,
  })  : _settings = settings,
        _auth = auth,
        _runtime = runtime,
        _http = httpClient ?? http.Client(),
        _maxAttempts = maxAttempts;

  final PosServerSettings _settings;
  final PosHubAuth _auth;
  final PosAppRuntimeConfig _runtime;
  final http.Client _http;
  final int _maxAttempts;

  /// Some resolvers wrongly append `:0`; that breaks HTTP and yields `wss://host:0/ws`,
  /// which cannot upgrade to WebSocket ([WebSocketChannelException]).
  static Uri coerceAwayExplicitZeroPort(Uri u) {
    if (!u.hasPort || u.port != 0) return u;
    final auth = StringBuffer();
    if (u.userInfo.isNotEmpty) {
      auth.write(u.userInfo);
      auth.write('@');
    }
    auth.write(u.host);
    final qs = u.hasQuery ? '?${u.query}' : '';
    final frag = u.hasFragment ? '#${u.fragment}' : '';
    return Uri.parse('${u.scheme}://$auth${u.path}$qs$frag');
  }

  void _validateHubForMode() {
    final hub = _settings.hubRoot;
    final tenant = _settings.tenantApiBaseUrl;
    if (_runtime.isLocal) {
      if (hub == null || hub.isEmpty) {
        throw StateError(
          'LAN hub URL required — ensure the POS PC is on and '
          'http://${PosAppRuntimeConfig.preferredHost}:${PosAppRuntimeConfig.preferredPort} resolves, '
          'or set a fallback IP in setup.',
        );
      }
      if (tenant != null && tenant.isNotEmpty) {
        if (PosServerSettings.normalizeRoot(hub) ==
            PosServerSettings.normalizeRoot(tenant)) {
          throw StateError('Cloud call blocked in LOCAL mode');
        }
      }
      return;
    }
    if (_runtime.isCloud && hub != null && hub.isNotEmpty) {
      if (!_runtime.cloudAllowsLanHubOrders) {
        throw StateError('LAN hub URL not used in cloud mode');
      }
    }
  }

  Uri _apiRoot() {
    _validateHubForMode();
    final base = _settings.baseUrl;
    if (base == null || base.isEmpty) {
      throw StateError(
        'LAN hub URL not set. Open setup (admin: Settings → Deployment) or use hostname '
        'http://${PosAppRuntimeConfig.preferredHost}:${PosAppRuntimeConfig.preferredPort}.',
      );
    }
    return coerceAwayExplicitZeroPort(Uri.parse(base));
  }

  Uri _url(String absoluteOrRelativePath) {
    final root = _apiRoot();
    final suffix = absoluteOrRelativePath.startsWith('/') ? absoluteOrRelativePath : '/$absoluteOrRelativePath';
    return root.resolve(suffix);
  }

  /// Omit port when absent or bogus (`0`) so [Uri] uses scheme defaults (443/80).
  static int? _wsExplicitPort(Uri root) {
    if (!root.hasPort) return null;
    final p = root.port;
    if (p <= 0 || p > 65535) return null;
    return p;
  }

  Uri wsUri(Uri httpRoot) {
    final root = coerceAwayExplicitZeroPort(httpRoot);
    final scheme = root.scheme == 'https' ? 'wss' : root.scheme == 'http' ? 'ws' : root.scheme;
    final port = _wsExplicitPort(root);
    return Uri(scheme: scheme, host: root.host, port: port, path: '/ws');
  }

  Uri get resolvedHttpRoot => _apiRoot();

  Uri get websocketUri => wsUri(resolvedHttpRoot);

  /// Adds `?token=` when a bearer token is stored (matches Node WebSocket verifier).
  Future<Uri> websocketUriAuthorized([String? bearerOverride]) async {
    final t = (bearerOverride ?? await _auth.bearerToken())?.trim();
    final base = websocketUri;
    if (t == null || t.isEmpty) return base;
    final q = Map<String, String>.from(base.queryParameters);
    q['token'] = t;
    return base.replace(queryParameters: q);
  }

  Future<Map<String, String>> _jsonHeaders() async {
    final h = <String, String>{'accept': 'application/json', 'content-type': 'application/json'};
    final t = await _auth.bearerToken();
    if (t != null && t.isNotEmpty) {
      h['authorization'] = 'Bearer $t';
    }
    return h;
  }

  Future<http.Response> _withRetry(Future<http.Response> Function() run) async {
    // Closures are often `() async =>` so headers can be awaited per attempt.
    for (var i = 0; i < _maxAttempts; i++) {
      try {
        final res = await run();
        final retryable = res.statusCode == 429 || (res.statusCode >= 500 && res.statusCode < 600);
        if (!retryable || i == _maxAttempts - 1) return res;
        await Future<void>.delayed(Duration(milliseconds: 300 * (i + 1)));
      } catch (_) {
        if (i == _maxAttempts - 1) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
      }
    }
    throw StateError('unreachable retry');
  }

  static bool _responseLooksLikeJson(http.Response res) {
    final ct = res.headers['content-type']?.toLowerCase() ?? '';
    if (ct.contains('text/html')) return false;
    final b = res.body.trimLeft();
    if (b.isEmpty) return false;
    return b.startsWith('[') || b.startsWith('{');
  }

  static String _bodySnippet(http.Response res, [int max = 160]) {
    final t = res.body.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max)}…';
  }

  Never _failResponse(http.Response res, String ctx) {
    String msg = 'HTTP ${res.statusCode}';
    try {
      final d = jsonDecode(res.body);
      if (d is Map && d['error'] != null) {
        msg += ': ${d['error']}';
      } else if (res.body.isNotEmpty) {
        msg += ' ${res.body}';
      }
    } catch (_) {
      if (res.body.isNotEmpty) msg += ' ${res.body}';
    }
    throw PosHubHttpException('$ctx — $msg');
  }

  /// `GET /orders` — lightweight rows (caller usually follows with `fetchOrder`).
  Future<List<dynamic>> listOrders({int limit = 50, int offset = 0}) async {
    final uri = _url('/orders').replace(queryParameters: {
      'limit': '$limit',
      'offset': '$offset',
    });
    final res = await _withRetry(() async => _http.get(uri, headers: await _jsonHeaders()));
    if (res.statusCode != 200) _failResponse(res, 'listOrders');
    if (!_responseLooksLikeJson(res)) {
      throw PosHubHttpException(
        'listOrders — expected JSON from Node hub at $resolvedHttpRoot, got non-JSON (${res.headers['content-type']}). '
        'Body starts: ${_bodySnippet(res)}. Use pos_server_base_url → http://<hub-ip>:3000 (not the tenant website).',
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List<dynamic>) {
      throw StateError('listOrders: expected JSON array');
    }
    return decoded;
  }

  /// `GET /orders/:id` — full envelope `{ order, items, payments }`.
  Future<Map<String, dynamic>> fetchOrder(String serverOrderId) async {
    final res = await _withRetry(
      () async => _http.get(_url('/orders/$serverOrderId'), headers: await _jsonHeaders()),
    );
    if (res.statusCode != 200) _failResponse(res, 'fetchOrder');
    if (!_responseLooksLikeJson(res)) {
      throw PosHubHttpException(
        'fetchOrder — expected JSON from hub at $resolvedHttpRoot, got ${_bodySnippet(res)}',
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('fetchOrder: expected JSON object');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> body) async {
    final res = await _withRetry(
      () async => _http.post(_url('/orders'), headers: await _jsonHeaders(), body: jsonEncode(body)),
    );
    if (res.statusCode != 201) _failResponse(res, 'createOrder');
    if (!_responseLooksLikeJson(res)) {
      throw PosHubHttpException('createOrder — expected JSON, got ${_bodySnippet(res)}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('createOrder: expected JSON object');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> patchOrder({
    required String serverOrderId,
    required Map<String, dynamic> body,
  }) async {
    final res = await _withRetry(
      () async => _http.patch(
        _url('/orders/$serverOrderId'),
        headers: await _jsonHeaders(),
        body: jsonEncode(body),
      ),
    );
    if (res.statusCode != 200) _failResponse(res, 'patchOrder');
    if (!_responseLooksLikeJson(res)) {
      throw PosHubHttpException('patchOrder — expected JSON, got ${_bodySnippet(res)}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('patchOrder: expected JSON object');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> patchOrderStatus({
    required String serverOrderId,
    required String status,
  }) async {
    final res = await _withRetry(
      () async => _http.patch(
        _url('/orders/$serverOrderId/status'),
        headers: await _jsonHeaders(),
        body: jsonEncode({'status': status}),
      ),
    );
    if (res.statusCode != 200) _failResponse(res, 'patchOrderStatus');
    if (!_responseLooksLikeJson(res)) {
      throw PosHubHttpException('patchOrderStatus — expected JSON, got ${_bodySnippet(res)}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('patchOrderStatus: expected JSON object');
    }
    return decoded;
  }

  Future<void> deleteOrderByServerId(String serverOrderId) async {
    final res = await _withRetry(
      () async => _http.delete(_url('/orders/$serverOrderId'), headers: await _jsonHeaders()),
    );
    if (res.statusCode != 204) _failResponse(res, 'deleteOrder');
  }

  /// Pushes the tenant API root (same as SharedPreferences `baseUrl` after common-api login) into
  /// Node `sync_meta` so `trigger-resync` can resolve the cloud host without `config.json` `api_base_url`.
  Future<void> pushTenantBaseUrlToHub(String apiBaseUrl) async {
    final trimmed = apiBaseUrl.trim();
    if (trimmed.isEmpty) return;
    final res = await _withRetry(
      () async => _http.post(
        _url('/sync/tenant-base'),
        headers: await _jsonHeaders(),
        body: jsonEncode(<String, dynamic>{'api_base_url': trimmed}),
      ),
    );
    if (res.statusCode != 200) _failResponse(res, 'pushTenantBaseUrlToHub');
    if (!_responseLooksLikeJson(res)) {
      throw PosHubHttpException(
        'pushTenantBaseUrlToHub — expected JSON from hub, got ${_bodySnippet(res)}',
      );
    }
  }

  /// Runs `POST /sync/trigger-resync` on the Node hub — pulls master data from cloud into the hub SQLite
  /// mirror (`cloud_mirror_entities`) so LAN sub devices receive items via [fetchMirrorPage].
  ///
  /// Requires Node `cloud_sync.node_cloud_engine_enabled` and valid cloud credentials on the server.
  Future<void> triggerHubMirrorResyncFromCloud() async {
    final res = await _withRetry(
      () async => _http.post(
        _url('/sync/trigger-resync'),
        headers: await _jsonHeaders(),
      ),
    );
    if (res.statusCode != 200) _failResponse(res, 'triggerHubMirrorResyncFromCloud');
    if (!_responseLooksLikeJson(res)) {
      throw PosHubHttpException(
        'triggerHubMirrorResyncFromCloud — expected JSON, got ${_bodySnippet(res)}',
      );
    }
  }

  /// Paginated rows from the hub cloud mirror (`cloud_mirror_entities`), same payload as legacy `/sync/items`.
  Future<Map<String, dynamic>> fetchMirrorPage(
    String resourceKey, {
    int limit = 200,
    int offset = 0,
  }) async {
    final enc = Uri.encodeComponent(resourceKey);
    final uri = _url('/sync/mirror/$enc').replace(queryParameters: {
      'limit': '$limit',
      'offset': '$offset',
    });
    final res = await _withRetry(() async => _http.get(uri, headers: await _jsonHeaders()));
    if (res.statusCode != 200) _failResponse(res, 'fetchMirrorPage');
    if (!_responseLooksLikeJson(res)) {
      throw PosHubHttpException(
        'fetchMirrorPage — expected JSON from hub at $resolvedHttpRoot, got ${_bodySnippet(res)}',
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('fetchMirrorPage: expected JSON object');
    }
    return decoded;
  }
}
