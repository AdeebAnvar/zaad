import 'dart:convert';

/// Canonical WebSocket envelopes for LAN MAIN ⇄ Flutter SUB sync.
abstract final class PosSyncEventTypes {
  static const connect = 'CONNECT';
  static const syncRequest = 'SYNC_REQUEST';
  static const syncResponse = 'SYNC_RESPONSE';
  static const itemUpsert = 'ITEM_UPSERT';
  static const categoryUpsert = 'CATEGORY_UPSERT';
  /// MAIN → SUB: full company identity for local login (users, branches, settings) after tenant link.
  static const companySnapshot = 'COMPANY_SNAPSHOT';
  /// MAIN → SUB: mirrored tenant REST JSON responses (subset applied on SUB).
  static const apiMirror = 'API_MIRROR';
  static const orderCreate = 'ORDER_CREATE';
  static const orderUpdate = 'ORDER_UPDATE';
  static const kotCreate = 'KOT_CREATE';
  static const paymentCreate = 'PAYMENT_CREATE';
  static const delete = 'DELETE';
  static const ack = 'ACK';
}

class PosSyncEnvelope {
  const PosSyncEnvelope({
    required this.eventId,
    required this.type,
    required this.payload,
    required this.timestamp,
    required this.deviceId,
  });

  final String eventId;
  final String type;
  final Map<String, dynamic> payload;

  /// Unix seconds (aligned with MAIN Node validation).
  final int timestamp;

  final String deviceId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'eventId': eventId,
        'type': type,
        'payload': payload,
        'timestamp': timestamp,
        'deviceId': deviceId,
      };

  String encode() => jsonEncode(toJson());

  static PosSyncEnvelope? tryDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return maybeEnvelope(decoded);
    } catch (_) {
      /* binary / noise */
    }
    return null;
  }

  /// Lenient parse for hub JSON (avoids silent drops when a field is the wrong JSON type).
  static PosSyncEnvelope? maybeEnvelope(dynamic decoded) {
    if (decoded == null || decoded is! Map) return null;
    final m = Map<String, dynamic>.from(decoded);
    final eventId = m['eventId']?.toString();
    final type = m['type']?.toString();
    if (eventId == null || eventId.isEmpty || type == null || type.isEmpty) {
      return null;
    }
    final payloadRaw = m['payload'];
    final payload =
        payloadRaw is Map ? Map<String, dynamic>.from(payloadRaw) : <String, dynamic>{};
    final deviceId = m['deviceId']?.toString() ?? '';
    return PosSyncEnvelope(
      eventId: eventId,
      type: type,
      payload: payload,
      timestamp: (m['timestamp'] is num)
          ? (m['timestamp'] as num).toInt()
          : (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      deviceId: deviceId,
    );
  }

  static PosSyncEnvelope fromJson(Map<String, dynamic> m) {
    final e = maybeEnvelope(m);
    if (e == null) {
      throw const FormatException('Invalid PosSyncEnvelope');
    }
    return e;
  }
}

/// Node journal rows in [SYNC_RESPONSE] are `{ effectiveMs, envelope }`; legacy items are raw envelopes.
abstract final class PosSyncJournalReplay {
  static PosSyncEnvelope? envelopeFromItem(dynamic item) {
    if (item is! Map) return null;
    final m = Map<String, dynamic>.from(item);
    final wrapped = m['envelope'];
    final envMap = wrapped is Map ? Map<String, dynamic>.from(wrapped) : m;
    return PosSyncEnvelope.maybeEnvelope(envMap);
  }

  static int watermarkMs(dynamic item, PosSyncEnvelope env) {
    if (item is Map) {
      final raw = Map<String, dynamic>.from(item)['effectiveMs'];
      if (raw is num) return raw.toInt();
    }
    final u = env.payload['updatedAt'];
    if (u is num) return u.toInt();
    return env.timestamp * 1000;
  }
}
