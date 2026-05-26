import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pos/app/di.dart';
import 'package:pos/core/isolate/app_isolate_service.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

/// Writes [sales_backup.xlsx] under [AppDirectories.media].
///
/// Full export is expensive — use [scheduleDebouncedRefresh] after order mutations;
/// [refreshFromDatabase] only for explicit/startup paths.
class SalesCsvBackup {
  SalesCsvBackup._();

  static const String fileName = 'sales_backup.xlsx';
  static const String metaFileName = 'sales_backup_meta.json';
  static const Duration _minRefreshInterval = Duration(minutes: 30);

  static const int _minOrderDropAbsolute = 10;
  static const double _minOrderDropFraction = 0.05;

  static Future<void> _writeQueue = Future<void>.value();
  static Timer? _debounceTimer;
  static AppDatabase? _debouncedDb;
  /// Last successful full workbook write (`refreshFromDatabase` / `refreshNow`).
  static DateTime _lastRefreshAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Coalesces bursts (checkout, KOT updates) — does not block the caller.
  static void scheduleDebouncedRefresh(
    AppDatabase db, {
    Duration delay = const Duration(seconds: 90),
  }) {
    _debouncedDb = db;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      final pending = _debouncedDb;
      _debouncedDb = null;
      if (pending == null) return;
      unawaited(
        refreshFromDatabase(pending).catchError((Object e, StackTrace st) {
          if (kDebugMode) {
            debugPrint('[SalesBackup] debounced refresh failed: $e\n$st');
          }
        }),
      );
    });
  }

  static Future<String> backupPath() async {
    final mediaDir = await AppDirectories.media();
    return p.join(mediaDir.path, fileName);
  }

  static Future<String> _metaPath() async {
    final mediaDir = await AppDirectories.media();
    return p.join(mediaDir.path, metaFileName);
  }

  static Future<int?> _readLastOrderCount() async {
    try {
      final file = File(await _metaPath());
      if (!await file.exists()) return null;
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final n = map['order_count'];
      if (n is int) return n;
      return int.tryParse(n?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeMeta(int orderCount) async {
    try {
      final file = File(await _metaPath());
      await file.writeAsString(
        jsonEncode({
          'order_count': orderCount,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  static bool _wouldShrinkExport({required int newCount, required int previousCount}) {
    if (newCount >= previousCount) return false;
    if (newCount < previousCount - _minOrderDropAbsolute) return true;
    final minAllowed = (previousCount * (1 - _minOrderDropFraction)).floor();
    return newCount < minAllowed;
  }

  /// Runs export on an internal queue. Prefer [scheduleDebouncedRefresh] on hot paths.
  static Future<void> refreshFromDatabase(AppDatabase db) async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefreshAt);
    if (elapsed >= _minRefreshInterval) {
      _debounceTimer?.cancel();
      _writeQueue = _writeQueue.then((_) => _safeRefresh(db));
      await _writeQueue;
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_minRefreshInterval - elapsed, () {
      _writeQueue = _writeQueue.then((_) => _safeRefresh(db));
    });
  }

  /// Bypass debounce (day close).
  static Future<void> refreshNow(AppDatabase db) async {
    _writeQueue = _writeQueue.then((_) => _safeRefresh(db));
    await _writeQueue;
  }

  static const List<String> _headers = [
    'id',
    'cart_id',
    'invoice_number',
    'reference_number',
    'total_amount',
    'discount_amount',
    'discount_type',
    'final_amount',
    'customer_name',
    'customer_email',
    'customer_phone',
    'customer_gender',
    'customer_address',
    'cash_amount',
    'credit_amount',
    'card_amount',
    'online_amount',
    'created_at',
    'status',
    'order_type',
    'delivery_partner',
    'driver_id',
    'driver_name',
  ];

  static List<Object?> _orderToRow(Order o) => <Object?>[
        o.id,
        o.cartId,
        o.invoiceNumber,
        o.referenceNumber ?? '',
        o.totalAmount,
        o.discountAmount,
        o.discountType ?? '',
        o.finalAmount,
        o.customerName ?? '',
        o.customerEmail ?? '',
        o.customerPhone ?? '',
        o.customerGender ?? '',
        o.cashAmount,
        o.creditAmount,
        o.cardAmount,
        o.onlineAmount,
        o.createdAt.toIso8601String(),
        o.status,
        o.orderType,
        o.deliveryPartner ?? '',
        o.driverId?.toString() ?? '',
        o.driverName ?? '',
      ];

  static Future<void> _safeRefresh(AppDatabase db) async {
    try {
      final session = await db.sessionDao.getActiveSession();
      final branchId = session?.branchId ?? 1;
      final orders = await db.ordersDao.getAllOrders(branchId: branchId);
      final previousCount = await _readLastOrderCount();

      if (previousCount != null && _wouldShrinkExport(newCount: orders.length, previousCount: previousCount)) {
        debugPrint(
          '[SalesBackup] Refusing shrink: $previousCount -> ${orders.length} orders '
          '(keeping existing $fileName)',
        );
        await _preserveCurrentExport(reason: 'shrink_${previousCount}_to_${orders.length}');
        return;
      }

      final rows = orders.map(_orderToRow).toList(growable: false);
      final List<int> bytes;
      if (rows.isEmpty) {
        bytes = buildSalesWorkbookBytesIsolate(rows);
      } else if (locator.isRegistered<AppIsolateService>()) {
        bytes = await locator<AppIsolateService>().run(buildSalesWorkbookBytesIsolate, rows);
      } else {
        bytes = await compute(buildSalesWorkbookBytesIsolate, rows);
      }

      final path = await backupPath();
      final file = File(path);

      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          await file.writeAsBytes(bytes);
          await _writeMeta(orders.length);
          _lastRefreshAt = DateTime.now();
          return;
        } on FileSystemException {
          if (attempt == 2) return;
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
      }
    } catch (e, st) {
      debugPrint('[SalesBackup] refresh failed: $e\n$st');
    }
  }

  static Future<void> _preserveCurrentExport({required String reason}) async {
    try {
      final path = await backupPath();
      final file = File(path);
      if (!await file.exists()) return;
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final dest = File(p.join(file.parent.path, 'sales_backup_preserved_${reason}_$stamp.xlsx'));
      await file.copy(dest.path);
    } catch (_) {}
  }
}

/// Builds the XLSX off the UI isolate ([compute] / [AppIsolateService]).
@pragma('vm:entry-point')
List<int> buildSalesWorkbookBytesIsolate(List<List<Object?>> rows) {
  final workbook = Workbook();
  try {
    final sheet = workbook.worksheets[0];
    sheet.name = 'Sales';

    for (var c = 0; c < SalesCsvBackup._headers.length; c++) {
      sheet.getRangeByIndex(1, c + 1).setText(SalesCsvBackup._headers[c]);
    }

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final r = i + 2;
      sheet.getRangeByIndex(r, 1).setNumber((row[0] as num).toDouble());
      sheet.getRangeByIndex(r, 2).setNumber((row[1] as num).toDouble());
      sheet.getRangeByIndex(r, 3).setText(row[2]!.toString());
      sheet.getRangeByIndex(r, 4).setText(row[3]!.toString());
      sheet.getRangeByIndex(r, 5).setNumber((row[4] as num).toDouble());
      sheet.getRangeByIndex(r, 6).setNumber((row[5] as num).toDouble());
      sheet.getRangeByIndex(r, 7).setText(row[6]!.toString());
      sheet.getRangeByIndex(r, 8).setNumber((row[7] as num).toDouble());
      sheet.getRangeByIndex(r, 9).setText(row[8]!.toString());
      sheet.getRangeByIndex(r, 10).setText(row[9]!.toString());
      sheet.getRangeByIndex(r, 11).setText(row[10]!.toString());
      sheet.getRangeByIndex(r, 12).setText(row[11]!.toString());
      sheet.getRangeByIndex(r, 13).setNumber((row[12] as num).toDouble());
      sheet.getRangeByIndex(r, 14).setNumber((row[13] as num).toDouble());
      sheet.getRangeByIndex(r, 15).setNumber((row[14] as num).toDouble());
      sheet.getRangeByIndex(r, 16).setNumber((row[15] as num).toDouble());
      sheet.getRangeByIndex(r, 17).setText(row[16]!.toString());
      sheet.getRangeByIndex(r, 18).setText(row[17]!.toString());
      sheet.getRangeByIndex(r, 19).setText(row[18]!.toString());
      sheet.getRangeByIndex(r, 20).setText(row[19]!.toString());
      sheet.getRangeByIndex(r, 21).setText(row[20]!.toString());
      sheet.getRangeByIndex(r, 22).setText(row[21]!.toString());
    }

    return workbook.saveAsStream();
  } finally {
    workbook.dispose();
  }
}
