import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:pos/core/network/lan_hub_health.dart';
import 'package:pos/core/network/local_hub_settings.dart';

/// Raised when a SUB terminal cannot reach the LAN hub for authoritative counters.
class HubCounterUnavailableException implements Exception {
  HubCounterUnavailableException([this.message =
      'Cannot reach MAIN hub. Connect to the shop network before taking orders.']);

  final String message;

  @override
  String toString() => message;
}

class HubCounterAllocateResult {
  const HubCounterAllocateResult({
    this.invoiceNumber,
    this.invoiceSuffix,
    this.pickupToken,
  });

  final String? invoiceNumber;
  final int? invoiceSuffix;
  final int? pickupToken;
}

/// Authoritative invoice + pickup token allocation via Node hub HTTP API.
abstract final class HubCounterClient {
  HubCounterClient._();

  static const _timeout = Duration(seconds: 5);

  static Uri? _countersUri(String path) {
    try {
      if (!GetIt.instance.isRegistered<LocalHubSettings>()) return null;
      final hub = GetIt.instance<LocalHubSettings>();
      final wsUrl = hub.isHubSub
          ? (hub.hubWsUrl ?? '')
          : hub.publishHubWsUrlOrLoopback;
      if (wsUrl.trim().isEmpty) return null;
      final health = lanHubHealthUriFromStoredWsUrl(wsUrl);
      if (health == null) return null;
      return health.replace(path: path);
    } catch (_) {
      return null;
    }
  }

  static Future<HubCounterAllocateResult?> allocate({
    required int branchId,
    required String prefix,
    bool invoice = false,
    bool pickupToken = false,
    int? localInvoiceMax,
    int? localPickupTokenMax,
  }) async {
    if (!invoice && !pickupToken) return null;
    final uri = _countersUri('/counters/allocate');
    if (uri == null) return null;

    final body = <String, dynamic>{
      'branchId': branchId,
      'prefix': prefix,
      if (invoice) 'allocateInvoice': true,
      if (pickupToken) 'allocatePickupToken': true,
      if (localInvoiceMax != null && localInvoiceMax > 0) 'localInvoiceMax': localInvoiceMax,
      if (localPickupTokenMax != null && localPickupTokenMax > 0)
        'localPickupTokenMax': localPickupTokenMax,
    };

    try {
      final r = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (r.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[HubCounterClient] allocate HTTP ${r.statusCode}: ${r.body}');
        }
        return null;
      }
      final map = jsonDecode(r.body);
      if (map is! Map) return null;
      final ok = map['ok'] == true;
      if (!ok) return null;
      return HubCounterAllocateResult(
        invoiceNumber: map['invoiceNumber']?.toString(),
        invoiceSuffix: _asInt(map['invoiceSuffix']),
        pickupToken: _asInt(map['pickupToken']),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[HubCounterClient] allocate failed: $e');
      return null;
    }
  }

  /// MAIN pushes local max counters to hub after connect / tenant link.
  static Future<void> seedFromLocalMax({
    required int branchId,
    required String prefix,
    required int lastInvoiceSuffix,
    required int lastPickupToken,
  }) async {
    if (branchId <= 0 || prefix.trim().isEmpty) return;
    final uri = _countersUri('/counters/seed');
    if (uri == null) return;

    final body = <String, dynamic>{
      'branchId': branchId,
      'prefix': prefix,
      if (lastInvoiceSuffix > 0) 'lastInvoiceSuffix': lastInvoiceSuffix,
      if (lastPickupToken > 0) 'lastPickupToken': lastPickupToken,
    };

    try {
      await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } catch (e) {
      if (kDebugMode) debugPrint('[HubCounterClient] seed failed: $e');
    }
  }

  static int? _asInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw');
  }
}
