import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/push_records_repository.dart';
import 'package:pos/data/repository_impl/push_local_to_push_records_mapper.dart';
import 'package:pos/domain/models/api/sync/sync_api.dart';
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

  @override
  Future<PushRecordsOutcome> pushSalesAndCreditSalesFromLocal() async {
    final logs = await _db.ordersDao.getUnsyncedOrderLogs();
    final unsyncedCustomers = await _db.customersDao.getUnsyncedCustomers();
    if (logs.isEmpty) {
      final customers = await _mapCustomersForPush(unsyncedCustomers);
      // Always hit the push endpoint after pull so proxies / server logs show the call.
      final empty = <String, dynamic>{
        'expenses': <dynamic>[],
        'customers': customers,
        'sales': <dynamic>[],
        'credit_sales': <dynamic>[],
      };
      if (kDebugMode) {
        debugPrint('[pushRecords] no unsynced order logs — sending empty push_records ping');
      }
      try {
        final res = await _api.pushRecords(empty);
        final code = res.statusCode;
        final ok = code != null && code >= 200 && code < 300;
        return PushRecordsOutcome(
          ordersPosted: 0,
          creditRowsPosted: 0,
          httpStatus: code,
          message: ok ? 'Push OK (no pending sales)' : 'Push failed (HTTP $code)',
        );
      } on DioException catch (e) {
        return PushRecordsOutcome(
          ordersPosted: 0,
          creditRowsPosted: 0,
          httpStatus: e.response?.statusCode,
          message: e.message ?? '$e',
        );
      } catch (e) {
        return PushRecordsOutcome(
          ordersPosted: 0,
          creditRowsPosted: 0,
          httpStatus: null,
          message: '$e',
        );
      }
    }

    final session = await _db.sessionDao.getActiveSession();
    final branchId = session?.branchId ?? 1;
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

      final saleUuid = _uuid.v4();
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
        creditUuid: _uuid.v4(),
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

    final body = <String, dynamic>{
      'expenses': <dynamic>[],
      'customers': customers,
      'sales': sales,
      'credit_sales': creditSales,
    };
    final cleanedBody = _removeNullsDeep(body);
    if (kDebugMode) {
      debugPrint(
        '[pushRecords] prepared payload expenses=0, customers=${customers.length}, sales=${sales.length}, credit_sales=${creditSales.length}',
      );
      if (_debugPrintSamplePayload && sales.isNotEmpty) {
        final sample = {
          'expenses': const <dynamic>[],
          'customers': customers.isNotEmpty ? [customers.first] : const <dynamic>[],
          'sales': [sales.first],
          'credit_sales': creditSales.isNotEmpty ? [creditSales.first] : <Map<String, dynamic>>[],
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
      }
      return PushRecordsOutcome(
        ordersPosted: sales.length,
        creditRowsPosted: creditSales.length,
        httpStatus: code,
        message: ok ? 'Push accepted' : 'Push failed (HTTP $code)',
      );
    } on DioException catch (e) {
      return PushRecordsOutcome(
        ordersPosted: sales.length,
        creditRowsPosted: creditSales.length,
        httpStatus: e.response?.statusCode,
        message: e.message ?? '$e',
      );
    } catch (e) {
      return PushRecordsOutcome(
        ordersPosted: sales.length,
        creditRowsPosted: creditSales.length,
        httpStatus: null,
        message: '$e',
      );
    }
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

      await _enrichToppingsForPush(line['toppings'], branchId: branchId);

      items[i] = line;
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
