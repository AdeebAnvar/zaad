import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/sync/hub_company_snapshot_publisher.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/core/network/cloud_sync_prerequisites.dart';
import 'package:pos/data/repository/push_records_repository.dart';
import 'package:pos/data/repository_impl/push_local_to_push_records_mapper.dart';
import 'package:pos/core/sync/company_bootstrap_persist.dart';
import 'package:pos/data/repository/pull_data_repository.dart';
import 'package:pos/domain/models/api/sync/sync_api.dart';
import 'package:pos/domain/models/item_model.dart';
import 'package:uuid/uuid.dart';

class _PaymentTypeIds {
  const _PaymentTypeIds({
    required this.defaultId,
    required this.cashId,
    required this.cardId,
    required this.onlineId,
  });

  final int defaultId;
  final int cashId;
  final int cardId;
  final int onlineId;
}

class PushRecordsRepositoryImpl implements PushRecordsRepository {
  PushRecordsRepositoryImpl(this._db, this._api);

  final AppDatabase _db;
  final SyncApi _api;

  static final Uuid _uuid = Uuid();
  static const bool _debugPrintSamplePayload = true;

  /// RFC 4122 DNS namespace — used only as v5 seed (not transmitted).
  static const String _v5NsDns = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

  /// Same local order always maps to the same sale `uuid`, so retries do not duplicate in admin.
  String _deterministicSaleUuid({
    required int branchId,
    required Map<String, dynamic> snap,
  }) {
    final oidRaw = snap['order_id'];
    final orderId =
        oidRaw is int ? oidRaw : int.tryParse(oidRaw?.toString() ?? '') ?? 0;
    if (orderId > 0) {
      return _uuid.v5(_v5NsDns, 'pos_sale|$branchId|$orderId');
    }
    final inv = snap['invoice_number']?.toString().trim() ?? '';
    final created = snap['created_at']?.toString().trim() ?? '';
    final deviceToken = '${snap['device_uuid'] ?? snap['tenant_device_uuid'] ?? ''}'.trim();
    return _uuid.v5(
      _v5NsDns,
      'pos_sale|$branchId|${deviceToken.isEmpty ? 'no_dev' : deviceToken}|$inv|$created',
    );
  }

  /// One credit row per sale; stable whenever the sale uuid is stable.
  String _deterministicCreditUuid(String saleUuid) =>
      _uuid.v5(_v5NsDns, 'pos_credit|$saleUuid');

  /// Snapshot JSON carries `order_id` (Drift orders.id). Only sync logs for orders on [branchId].
  Future<bool> _orderLogMatchesBranch(OrderLog log, int branchId) async {
    Map<String, dynamic>? snap;
    try {
      final decoded = jsonDecode(log.orderJson);
      if (decoded is Map) snap = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return false;
    }
    if (snap == null) return false;
    final oid = snap['order_id'];
    final localId = oid is int ? oid : int.tryParse(oid?.toString() ?? '');
    if (localId == null) return false;
    final row = await _db.ordersDao.getOrderById(localId);
    return row != null && row.branchId == branchId;
  }

  @override
  Future<PushRecordsOutcome> pushSalesAndCreditSalesFromLocal() async {
    try {
      await assertTenantCloudSyncConfigured();
    } catch (e) {
      return PushRecordsOutcome(
        ordersPosted: 0,
        creditRowsPosted: 0,
        settleRowsPosted: 0,
        httpStatus: null,
        message: '$e',
      );
    }
    final unsyncedCustomers = await _db.customersDao.getUnsyncedCustomers();
    final session = await _db.sessionDao.getActiveSession();
    final branchId = session?.branchId ?? 1;

    final settlePending = await _pendingSettleSalesForBranch(branchId);

    final allLogs = await _db.ordersDao.getUnsyncedOrderLogs();
    final logs = <OrderLog>[];
    for (final log in allLogs) {
      if (await _orderLogMatchesBranch(log, branchId)) logs.add(log);
    }

    if (logs.isEmpty) {
      final customers = await _mapCustomersForPush(unsyncedCustomers);
      final settleSales = settlePending.maps;
      final settleIds = settlePending.ids;
      // Always hit the push endpoint after pull so proxies / server logs show the call.
      final empty = <String, dynamic>{
        'expenses': <dynamic>[],
        'customers': customers,
        'sales': <dynamic>[],
        'credit_sales': <dynamic>[],
        'settle_sales': settleSales,
      };
      final cleanedEmpty = _removeNullsDeep(empty);
      if (kDebugMode) {
        debugPrint(
          '[pushRecords] no unsynced order logs — ping with settle_sales=${settleSales.length}, customers=${customers.length}',
        );
      }
      try {
        final res = await _api.pushRecords(cleanedEmpty);
        final code = res.statusCode;
        final ok = code != null && code >= 200 && code < 300;
        if (ok) {
          await _fetchBootstrapMirrorBestEffort();
          await _db.settleSalesOutboxDao.markSynced(settleIds);
        }
        return PushRecordsOutcome(
          ordersPosted: 0,
          creditRowsPosted: 0,
          settleRowsPosted: settleSales.length,
          httpStatus: code,
          message: ok ? 'Push OK (no pending sales)' : 'Push failed (HTTP $code)',
        );
      } on DioException catch (e) {
        return PushRecordsOutcome(
          ordersPosted: 0,
          creditRowsPosted: 0,
          settleRowsPosted: settleSales.length,
          httpStatus: e.response?.statusCode,
          message: e.message ?? '$e',
        );
      } catch (e) {
        return PushRecordsOutcome(
          ordersPosted: 0,
          creditRowsPosted: 0,
          settleRowsPosted: settleSales.length,
          httpStatus: null,
          message: '$e',
        );
      }
    }

    final userId = session?.userId ?? 1;

    final pay = await _resolvePaymentTypeIds();

    final sales = <Map<String, dynamic>>[];
    final creditSales = <Map<String, dynamic>>[];
    final customers = await _mapCustomersForPush(unsyncedCustomers);

    for (final log in logs) {
      Map<String, dynamic> snap;
      try {
        final decoded = jsonDecode(log.orderJson);
        if (decoded is! Map) continue;
        snap = Map<String, dynamic>.from(decoded);
      } catch (_) {
        continue;
      }

      final saleUuid =
          _deterministicSaleUuid(branchId: branchId, snap: snap);
      final phone = snap['customer_phone']?.toString().trim();
      final customerUuid = await _customerUuidForPhone(phone);

      final createdDt = DateTime.tryParse(snap['created_at']?.toString() ?? '') ?? DateTime.now();

      final sale = PushLocalToPushRecordsMapper.buildSale(
        snap: snap,
        saleUuid: saleUuid,
        branchId: branchId,
        userId: userId,
        defaultPaymentTypeId: pay.defaultId,
        cashPaymentTypeId: pay.cashId,
        cardPaymentTypeId: pay.cardId,
        onlinePaymentTypeId: pay.onlineId,
        customerUuid: customerUuid,
      );

      await _enrichSaleLineItemsForPush(sale, branchId: branchId);

      sales.add(sale);

      final creditAmt = PushLocalToPushRecordsMapper.resolvedCreditAmount(snap);
      final creditRow = PushLocalToPushRecordsMapper.buildCreditForSale(
        creditUuid: _deterministicCreditUuid(saleUuid),
        saleUuid: saleUuid,
        creditAmount: creditAmt,
        branchId: branchId,
        userId: userId,
        customerUuid: customerUuid,
        created: createdDt,
      );
      if (creditRow != null) {
        creditRow.removeWhere((_, v) => v == null);
        creditSales.add(creditRow);
      }
    }

    final settleSales = settlePending.maps;
    final settleIds = settlePending.ids;

    final body = <String, dynamic>{
      'expenses': <dynamic>[],
      'customers': customers,
      'sales': sales,
      'credit_sales': creditSales,
      'settle_sales': settleSales,
    };
    final cleanedBody = _removeNullsDeep(body);
    if (kDebugMode) {
      debugPrint(
        '[pushRecords] prepared payload expenses=0, customers=${customers.length}, sales=${sales.length}, credit_sales=${creditSales.length}, settle_sales=${settleSales.length}',
      );
      if (_debugPrintSamplePayload && sales.isNotEmpty) {
        final sample = {
          'expenses': const <dynamic>[],
          'customers': customers.isNotEmpty ? [customers.first] : const <dynamic>[],
          'sales': [sales.first],
          'credit_sales': creditSales.isNotEmpty ? [creditSales.first] : <Map<String, dynamic>>[],
          'settle_sales': settleSales.isNotEmpty ? [settleSales.first] : <Map<String, dynamic>>[],
        };
        debugPrint('[pushRecords] sample payload => ${jsonEncode(_removeNullsDeep(sample))}');
      }
    }

    try {
      final res = await _api.pushRecords(cleanedBody);
      final code = res.statusCode;
      final ok = code != null && code >= 200 && code < 300;
      if (kDebugMode) {
        debugPrint('[pushRecords] response status=$code, ok=$ok');
      }
      if (ok) {
        await _db.ordersDao.markOrderLogsSynced(logs.map((e) => e.id).toList());
        for (final c in unsyncedCustomers) {
          await _db.customersDao.markAsSynced(c.id);
        }
        await _db.settleSalesOutboxDao.markSynced(settleIds);
      }
      return PushRecordsOutcome(
        ordersPosted: sales.length,
        creditRowsPosted: creditSales.length,
        settleRowsPosted: settleSales.length,
        httpStatus: code,
        message: ok ? 'Push accepted' : 'Push failed (HTTP $code)',
      );
    } on DioException catch (e) {
      return PushRecordsOutcome(
        ordersPosted: sales.length,
        creditRowsPosted: creditSales.length,
        settleRowsPosted: settleSales.length,
        httpStatus: e.response?.statusCode,
        message: e.message ?? '$e',
      );
    } catch (e) {
      return PushRecordsOutcome(
        ordersPosted: sales.length,
        creditRowsPosted: creditSales.length,
        settleRowsPosted: settleSales.length,
        httpStatus: null,
        message: '$e',
      );
    }
  }

  Future<({List<Map<String, dynamic>> maps, List<int> ids})> _pendingSettleSalesForBranch(
    int branchId,
  ) async {
    final rows = await _db.settleSalesOutboxDao.getUnsyncedForBranch(branchId);
    final maps = <Map<String, dynamic>>[];
    final ids = <int>[];
    for (final r in rows) {
      try {
        final decoded = jsonDecode(r.payloadJson);
        if (decoded is Map) {
          maps.add(Map<String, dynamic>.from(decoded));
          ids.add(r.id);
        }
      } catch (_) {
        /* skip malformed */
      }
    }
    return (maps: maps, ids: ids);
  }

  Future<List<Map<String, dynamic>>> _mapCustomersForPush(
    List<Customer> rows,
  ) async {
    final out = <Map<String, dynamic>>[];
    for (final c in rows) {
      var uuid = c.recordUuid?.trim();
      if (uuid == null || uuid.isEmpty) {
        uuid = _uuid.v4();
        await _db.customersDao.updateCustomer(
          CustomersCompanion(
            id: Value(c.id),
            recordUuid: Value(uuid),
          ),
        );
      }

      out.add(<String, dynamic>{
        'uuid': uuid,
        'phone': (c.phone ?? '').trim(),
        'name': c.name.trim(),
        'email': (c.email ?? '').trim(),
        'address': (c.address ?? '').trim(),
        'gender': (c.gender ?? '').trim(),
        'branch_id': (c.branchId ?? 1).toString(),
        'created_at': PushLocalToPushRecordsMapper.formatApiDateTime(c.createdAt),
      });
    }
    return out;
  }

  /// Server `sale_order_items.category_id` is NOT NULL — fill from local [Items] or [pull_item_rows].
  Future<void> _enrichSaleLineItemsForPush(
    Map<String, dynamic> sale, {
    required int branchId,
  }) async {
    final items = sale['items'];
    if (items is! List) return;

    for (var i = 0; i < items.length; i++) {
      final raw = items[i];
      if (raw is! Map) continue;
      final line = Map<String, dynamic>.from(raw);

      final itemId = (line['item_id'] as num?)?.toInt() ?? int.tryParse('${line['item_id']}') ?? 0;
      if (itemId <= 0) continue;

      int? categoryId = (line['category_id'] as num?)?.toInt();
      String? itemName = line['item_name']?.toString().trim();
      if (itemName != null && itemName.isEmpty) itemName = null;

      final localItem = await _db.itemDao.getItemById(itemId);
      if (localItem != null) {
        categoryId ??= localItem.categoryId;
        itemName ??= localItem.name;
        final other = localItem.otherName.trim();
        if (other.isNotEmpty) line['other_item_name'] = other;
      }

      if (categoryId == null || categoryId <= 0) {
        final pull = await (_db.select(_db.pullItemRows)..where((t) => t.id.equals(itemId))).getSingleOrNull();
        if (pull != null) {
          categoryId = pull.categoryId;
          itemName ??= pull.itemName;
          final other = pull.itemOtherName?.toString().trim() ?? '';
          if (other.isNotEmpty) line['other_item_name'] = other;
          final type = pull.itemType.trim();
          if (type.isNotEmpty) line['item_type'] = type;
        }
      }

      line['category_id'] = categoryId ?? 1;
      if (itemName != null && itemName.isNotEmpty) line['item_name'] = itemName;

      final variantLocalId = (line['item_variant_id'] as num?)?.toInt();
      final resolvedPriceId = await _resolveSaleItemPriceId(
        itemId: itemId,
        variantLocalId: variantLocalId,
        branchId: branchId,
      );
      if (resolvedPriceId != null && resolvedPriceId > 0) {
        line['price_id'] = resolvedPriceId;
      }

      await _enrichToppingsForPush(line['toppings'], branchId: branchId);

      items[i] = line;
    }
  }

  static const double _kItemPriceMatchTol = 0.02;

  bool _isLikelyBaseItemprice(Itemprice p) {
    if (p.variationOptions.isNotEmpty) return false;
    final voi = p.variationOptionIds;
    if (voi == null) return true;
    if (voi is List && voi.isEmpty) return true;
    final s = voi.toString().replaceAll(RegExp(r'[\s\[\],]'), '');
    return s.isEmpty;
  }

  String _itempriceVariationLabel(Itemprice p) {
    final vo = p.variationOptions;
    if (vo.isEmpty) return '';
    final parts = <String>[];
    for (final x in vo) {
      if (x is Map) {
        final n = '${x['name'] ?? x['option'] ?? ''}'.trim();
        if (n.isNotEmpty) parts.add(n);
      } else {
        final n = x?.toString().trim() ?? '';
        if (n.isNotEmpty) parts.add(n);
      }
    }
    return parts.join(' / ');
  }

  /// Maps a sale line to the tenant **`itemprice.id`** (not local `item_variants.id` / `items.id`).
  Future<int?> _resolveSaleItemPriceId({
    required int itemId,
    required int? variantLocalId,
    required int branchId,
  }) async {
    try {
      final pull = await (_db.select(_db.pullItemRows)..where((t) => t.id.equals(itemId))).getSingleOrNull();
      final raw = pull?.itempriceJson?.trim();
      if (raw == null || raw.isEmpty || raw == 'null') return null;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;

      final prices = <Itemprice>[];
      for (final e in decoded) {
        if (e is! Map) continue;
        try {
          prices.add(Itemprice.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
      if (prices.isEmpty) return null;

      var scoped = prices.where((p) => p.branchId == branchId || p.branchId == 0).toList();
      if (scoped.isEmpty) scoped = prices;

      final localItem = await _db.itemDao.getItemById(itemId);
      final basePx = localItem?.price ?? 0.0;

      if (variantLocalId == null || variantLocalId <= 0) {
        Itemprice? basePick;
        for (final p in scoped) {
          if (_isLikelyBaseItemprice(p)) {
            basePick = p;
            break;
          }
        }
        if (basePick == null) {
          for (final p in scoped) {
            if ((p.price - basePx).abs() <= _kItemPriceMatchTol) {
              basePick = p;
              break;
            }
          }
        }
        basePick ??= scoped.first;
        return basePick.id;
      }

      final vRow = await _db.itemDao.getVariantById(variantLocalId);
      if (vRow == null) {
        for (final p in scoped) {
          if ((p.price - basePx).abs() <= _kItemPriceMatchTol) return p.id;
        }
        return scoped.first.id;
      }

      final vn = vRow.name.trim().toLowerCase();
      final vp = vRow.price;
      final cand = scoped.where((p) => (p.price - vp).abs() <= _kItemPriceMatchTol).toList();
      if (cand.isEmpty) {
        return scoped.first.id;
      }
      if (cand.length == 1) return cand.first.id;

      for (final p in cand) {
        final lbl = _itempriceVariationLabel(p).toLowerCase();
        if (lbl.isNotEmpty && (lbl.contains(vn) || vn.contains(lbl))) {
          return p.id;
        }
      }
      final tail = vn.split('/').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      for (final p in cand) {
        final lbl = _itempriceVariationLabel(p).toLowerCase();
        if (tail.isNotEmpty && tail.every((t) => lbl.contains(t))) {
          return p.id;
        }
      }
      return cand.first.id;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[pushRecords] resolve price_id item=$itemId: $e\n$st');
      }
      return null;
    }
  }

  Future<void> _enrichToppingsForPush(
    dynamic toppings, {
    required int branchId,
  }) async {
    if (toppings is! List) return;
    for (var i = 0; i < toppings.length; i++) {
      final t = toppings[i];
      if (t is! Map) continue;
      final m = Map<String, dynamic>.from(t);
      m.putIfAbsent('branch_id', () => branchId);
      toppings[i] = m;
    }
  }

  Future<String?> _customerUuidForPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return null;
    final rows = await _db.customersDao.getCustomersByPhone(phone);
    if (rows.isEmpty) return null;
    final c = rows.first;
    final uuid = c.recordUuid?.trim();
    if (uuid != null && uuid.isNotEmpty) return uuid;
    final sid = c.serverId?.trim();
    if (sid != null && sid.isNotEmpty) return sid;
    return null;
  }

  Future<_PaymentTypeIds> _resolvePaymentTypeIds() async {
    final rows =
        await (_db.select(_db.pullFloorRows)..where((t) => t.resourceKey.equals('paymentMethods'))).get();

    final first = rows.isEmpty ? 1 : rows.first.id;

    int pick(List<String> needles) {
      for (final n in needles) {
        final nLower = n.toLowerCase();
        for (final r in rows) {
          final slug = (r.paymentMethodSlug ?? '').toLowerCase();
          final name = (r.paymentMethodName ?? r.floorName ?? '').toLowerCase();
          if (slug.contains(nLower) || name.contains(nLower)) return r.id;
        }
      }
      return first;
    }

    return _PaymentTypeIds(
      defaultId: first,
      cashId: pick(['cash']),
      cardId: pick(['card', 'visa', 'master']),
      onlineId: pick(['online', 'upi', 'bank']),
    );
  }

  /// After push, refresh bootstrap so Dio mirrors latest company JSON to LAN SUBs ([API_MIRROR]).
  Future<void> _fetchBootstrapMirrorBestEffort() async {
    try {
      final res = await _api.fetchBootstrap();
      await persistCompanyBootstrapFromApiBody(res.data, broadcastToLanHub: false);

      final deferPullMirror =
          locator.isRegistered<PullDataRepository>() && locator<PullDataRepository>().pendingDeferredLanHubMirror;

      if (!deferPullMirror) {
        unawaited(_companySnapshotToLanHubAfterIdle());
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[pushRecords] bootstrap mirror skipped: $e\n$st');
      }
    }
  }

  /// Short-lived WS after REST so PRIMARY inbound + tenant HTTP are not contending on the wire.
  Future<void> _companySnapshotToLanHubAfterIdle() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    try {
      await HubCompanySnapshotPublisher.broadcastAfterTenantLink(_db);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[pushRecords] LAN COMPANY_SNAPSHOT skipped: $e\n$st');
      }
    }
  }

  dynamic _removeNullsDeep(dynamic value) {
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((k, v) {
        final cleaned = _removeNullsDeep(v);
        if (cleaned != null) {
          out[k.toString()] = cleaned;
        }
      });
      return out;
    }
    if (value is List) {
      return value.map(_removeNullsDeep).where((e) => e != null).toList();
    }
    return value;
  }
}
