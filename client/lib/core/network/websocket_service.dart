import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:pos/core/network/hub_lan_catalog_live_sync.dart';
import 'package:pos/core/network/pos_api_service.dart';
import 'package:pos/core/network/pos_server_settings.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:pos/features/orders/data/hub_orders_sync.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

enum PosHubConnectionState {
  idle,
  disconnected,
  connecting,
  connected,
  reconnectWaiting,
}

/// Singleton-style WebSocket client: `/ws?token=` + hub cache projection (`NEW_ORDER`, `ORDER_UPDATED`, `ORDER_DELETED`).
///
/// Also reacts to `ITEMS_UPDATED` / `DATA_SYNCED` from the Node hub (cloud mirror refresh)
/// so satellite terminals update catalog live via [HubLanCatalogLiveSync].
class HubWebSocketService {
  HubWebSocketService(
    this._settings,
    this._api,
    this._sync, {
    HubLanCatalogLiveSync? catalogLive,
    HubOrdersLiveSync? ordersLive,
  })  : _catalogLive = catalogLive,
        _ordersLive = ordersLive;

  final PosServerSettings _settings;
  final PosApiService _api;
  final HubOrdersSync _sync;
  final HubLanCatalogLiveSync? _catalogLive;
  final HubOrdersLiveSync? _ordersLive;

  final ValueNotifier<PosHubConnectionState> connection =
      ValueNotifier(PosHubConnectionState.idle);

  bool _stopRequested = false;
  int _attempt = 0;
  Future<void>? _runner;
  WebSocketChannel? _channel;

  /// Local LAN mode only — cloud installs never open `/ws`.
  bool get isConfigured => _settings.enablesLanWebSocket;

  void _bumpOrderListeners() {
    _ordersLive?.notifyHubOrdersChanged();
  }

  Future<void> hydrateCacheIfConfigured() async {
    if (!isConfigured) return;
    try {
      var offset = 0;
      const limit = 100;
      for (;;) {
        final slice = await _api.listOrders(limit: limit, offset: offset);
        if (slice.isEmpty) break;
        for (final row in slice) {
          final m = row is Map ? Map<String, dynamic>.from(row) : null;
          if (m == null) continue;
          final sidRaw = m['id'];
          final sid = sidRaw == null ? '' : '$sidRaw';
          if (sid.isEmpty) continue;
          try {
            final detail = await _api.fetchOrder(sid);
            await _sync.applyHubEnvelope(detail);
          } catch (e, st) {
            debugPrint('[hub] hydrate order $sid failed: $e\n$st');
          }
        }
        if (slice.length < limit) break;
        offset += limit;
      }
    } catch (e, st) {
      debugPrint('[hub] hydrate failed: $e\n$st');
    }
    _bumpOrderListeners();
  }

  void startRealtimeIfConfigured() {
    if (!isConfigured) {
      connection.value = PosHubConnectionState.idle;
      return;
    }
    _stopRequested = false;
    _runner ??= _socketLoop();
  }

  Future<void> stop() async {
    _stopRequested = true;
    try {
      await _channel?.sink.close(ws_status.normalClosure);
    } catch (_) {}
    _channel = null;
    _runner = null;
    connection.value = PosHubConnectionState.disconnected;
  }

  Future<void> _socketLoop() async {
    while (!_stopRequested && isConfigured) {
      connection.value = PosHubConnectionState.connecting;
      try {
        final uri = await _api.websocketUriAuthorized();
        debugPrint('[hub] WebSocket connecting → $uri');
        final ch = WebSocketChannel.connect(uri);
        _channel = ch;
        // Consume connection handshake failures here; otherwise [WebSocketChannel.ready]
        // completes with an error that becomes an unhandled async exception while the
        // stream path still surfaces the same error to [_listenChannel].
        await ch.ready;
        debugPrint('[hub] WebSocket connected');
        await _listenChannel(ch);
      } catch (e, st) {
        debugPrint('[hub] websocket session error: $e\n$st');
      } finally {
        if (!_stopRequested) {
          connection.value = PosHubConnectionState.reconnectWaiting;
        }
      }

      if (_stopRequested || !isConfigured) break;

      _attempt++;
      final delayMs = math.min(
        30_000,
        (800 * math.pow(1.7, math.min(_attempt, 8))).toInt(),
      );
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }

    connection.value = PosHubConnectionState.disconnected;
    _runner = null;
  }

  Future<void> _listenChannel(WebSocketChannel ch) async {
    connection.value = PosHubConnectionState.connected;
    _attempt = 0;

    await for (final raw in ch.stream) {
      if (_stopRequested) break;
      if (raw is String) {
        unawaited(
          _handleMessage(raw).catchError((Object e, StackTrace st) {
            debugPrint('[hub] ws message async error: $e\n$st');
          }),
        );
      }
    }

    debugPrint('[hub] WebSocket stream ended (disconnect or server closed)');
    connection.value = PosHubConnectionState.disconnected;
  }

  Future<void> _handleMessage(String raw) async {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final type = decoded['type'];

      if (type == 'ORDER_DELETED') {
        final payload = decoded['payload'];
        if (payload is Map<String, dynamic>) {
          final sid = payload['id'];
          if (sid != null) {
            await _sync.evictByServerId('$sid');
          }
        }
        _bumpOrderListeners();
        return;
      }

      final typeStr = type?.toString() ?? '';
      if (typeStr == 'ITEMS_UPDATED' || typeStr == 'DATA_SYNCED') {
        _catalogLive?.onHubMasterDataSignal(typeStr);
        return;
      }

      if (type != 'NEW_ORDER' && type != 'ORDER_UPDATED') return;
      final payload = decoded['payload'];
      if (payload is! Map<String, dynamic>) return;
      await _sync.applyHubEnvelope(payload);
      _bumpOrderListeners();
    } catch (e, st) {
      debugPrint('[hub] ws message handling failed: $e\n$st');
    }
  }
}
