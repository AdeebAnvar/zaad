import 'dart:convert';

import 'package:pos/data/local/drift_database.dart';

/// Cash / card / online collected against prior credit after day closing.
class CreditRecoveryBreakdown {
  const CreditRecoveryBreakdown({
    this.cash = 0,
    this.card = 0,
    this.online = 0,
  });

  final double cash;
  final double card;
  final double online;

  double get total => cash + card + online;

  static const zero = CreditRecoveryBreakdown();
}

Map<String, dynamic> _decodeHubMetadata(String? raw) {
  final t = raw?.trim();
  if (t == null || t.isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(t);
    if (decoded is Map<String, dynamic>) return Map<String, dynamic>.from(decoded);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return <String, dynamic>{};
}

/// Last local mutation time stored in [Order.hubMetadata] (falls back to [Order.createdAt]).
DateTime orderHubLastUpdatedAt(Order o) {
  final map = _decodeHubMetadata(o.hubMetadata);
  final u = map['updatedAt'];
  if (u is int) return DateTime.fromMillisecondsSinceEpoch(u);
  if (u is num) return DateTime.fromMillisecondsSinceEpoch(u.toInt());
  return o.createdAt;
}

/// Whether an order should affect the current day-closing window (sale or post-close credit payment).
bool orderInDayCloseWindow(Order o, DateTime? cutoff) {
  if (cutoff == null) return true;
  return o.createdAt.isAfter(cutoff) || orderHubLastUpdatedAt(o).isAfter(cutoff);
}

bool orderCreatedInDayCloseWindow(Order o, DateTime? cutoff) {
  if (cutoff == null) return true;
  return o.createdAt.isAfter(cutoff);
}

/// Appends one credit-collection row and returns JSON for [Order.hubMetadata].
String hubMetadataWithCreditPayment({
  required String? existingHubMetadata,
  required double amount,
  required String type,
}) {
  final meta = _decodeHubMetadata(existingHubMetadata);
  final log = <Map<String, dynamic>>[];
  final existing = meta['creditPayments'];
  if (existing is List) {
    for (final e in existing) {
      if (e is Map) log.add(Map<String, dynamic>.from(e));
    }
  }
  log.add(<String, dynamic>{
    'at': DateTime.now().millisecondsSinceEpoch,
    'amount': amount,
    'type': type.trim().toLowerCase(),
  });
  meta['creditPayments'] = log;
  meta['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
  return jsonEncode(meta);
}

CreditRecoveryBreakdown creditRecoveryAfterCheckpoint(Order o, DateTime cutoff) {
  final map = _decodeHubMetadata(o.hubMetadata);
  final entries = map['creditPayments'];
  if (entries is List && entries.isNotEmpty) {
    var cash = 0.0;
    var card = 0.0;
    var online = 0.0;
    final cutoffMs = cutoff.millisecondsSinceEpoch;
    for (final raw in entries) {
      if (raw is! Map) continue;
      final at = raw['at'];
      final ms = at is int ? at : (at is num ? at.toInt() : null);
      if (ms == null || ms <= cutoffMs) continue;
      final amount = raw['amount'];
      final pay = amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0;
      if (pay <= 0.009) continue;
      switch ('${raw['type']}'.trim().toLowerCase()) {
        case 'cash':
          cash += pay;
          break;
        case 'card':
          card += pay;
          break;
        case 'online':
          online += pay;
          break;
      }
    }
    if (cash + card + online > 0.009) {
      return CreditRecoveryBreakdown(cash: cash, card: card, online: online);
    }
  }

  // Legacy rows: credit paid after close before payment log existed.
  if (!o.createdAt.isAfter(cutoff) && orderHubLastUpdatedAt(o).isAfter(cutoff)) {
    return CreditRecoveryBreakdown(
      cash: o.cashAmount,
      card: o.cardAmount,
      online: o.onlineAmount,
    );
  }
  return CreditRecoveryBreakdown.zero;
}

List<dynamic>? creditPaymentsFromHubMetadata(String? raw) {
  final list = _decodeHubMetadata(raw)['creditPayments'];
  return list is List ? list : null;
}
