import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/core/sync/ws_detach_done_errors.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Mirrors successful tenant API JSON responses from MAIN Flutter to SUBs via the Node hub.
///
/// Large bodies are skipped to stay below typical WS frame limits (~15 MiB on Node).
class HubApiMirrorPublisher {
  HubApiMirrorPublisher._();

  static const _maxApproxBytes = 10 * 1024 * 1024;

  static Future<void>? _mirrorTail;

  static LocalHubSettings? _eligibleHubOrNull() {
    try {
      final g = GetIt.instance;
      if (!g.isRegistered<LocalHubSettings>()) return null;
      final hub = g<LocalHubSettings>();
      if (hub.blocksTenantCloudRest) return null;
      if (hub.publishHubWsUrlOrLoopback.isEmpty) return null;
      return hub;
    } catch (_) {
      return null;
    }
  }

  static void scheduleMirror({
    required String path,
    required String method,
    required int statusCode,
    required Object? body,
  }) {
    if (body == null || (body is! Map && body is! List)) return;

    Future.microtask(() {
      final hub = _eligibleHubOrNull();
      if (hub == null) return;

      dynamic serializableBody;
      if (body is Map) {
        serializableBody = body is Map<String, dynamic>
            ? body
            : Map<String, dynamic>.from(
                body.map((k, v) => MapEntry(k.toString(), v)),
              );
      } else if (body is List) {
        serializableBody = body;
      } else {
        return;
      }

      final envelopePayload = <String, dynamic>{
        'path': path,
        'method': method,
        'statusCode': statusCode,
        'body': serializableBody,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      try {
        final approx = utf8.encode(jsonEncode(envelopePayload)).length;
        if (approx > _maxApproxBytes) {
          if (kDebugMode) {
            debugPrint('[HubApiMirrorPublisher] skip oversize (${approx}b) path=$path');
          }
          return;
        }
      } catch (_) {
        return;
      }

      final h = hub;
      _mirrorTail = (_mirrorTail ?? Future<void>.value())
          .then((_) => _publishOne(h, envelopePayload))
          .catchError((Object? _, StackTrace __) {});
    });
  }

  static Future<void> _publishOne(LocalHubSettings hub, Map<String, dynamic> mirrorPayload) async {
    WebSocketChannel? ch;
    try {
      await hub.resolveOrAllocateDeviceId(() => const Uuid().v4());
      final deviceId = hub.requireDeviceId();
      final uri = Uri.parse(hub.publishHubWsUrlOrLoopback.trim());
      ch = WebSocketChannel.connect(uri);
      detachWebSocketSinkDone(ch);

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final env = PosSyncEnvelope(
        eventId: const Uuid().v4(),
        type: PosSyncEventTypes.apiMirror,
        payload: mirrorPayload,
        timestamp: nowMs ~/ 1000,
        deviceId: deviceId,
      );
      ch.sink.add(env.encode());
    } catch (e, st) {
      if (kDebugMode) debugPrint('[HubApiMirrorPublisher] send failed: $e\n$st');
    } finally {
      try {
        await ch?.sink.close();
      } catch (_) {
        /* ignore */
      }
    }
  }
}
