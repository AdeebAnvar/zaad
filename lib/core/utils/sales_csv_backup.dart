import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

class SalesCsvBackup {
  SalesCsvBackup._();

  static const String fileName = 'sales_backup.xlsx';
  static Future<void> _writeQueue = Future<void>.value();

  static Future<String> backupPath() async {
    final mediaDir = await AppDirectories.media();
    return p.join(mediaDir.path, fileName);
  }

  static Future<void> refreshFromDatabase(AppDatabase db) async {
    // Queue writes to avoid concurrent access from rapid order updates.
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

  static Future<void> _safeRefresh(AppDatabase db) async {
    try {
      final orders = await db.ordersDao.getAllOrders();
      final path = await backupPath();
      final file = File(path);
      final workbook = Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'Sales';

      // Header row
      for (var c = 0; c < _headers.length; c++) {
        sheet.getRangeByIndex(1, c + 1).setText(_headers[c]);
      }

      // Data rows
      for (var i = 0; i < orders.length; i++) {
        final o = orders[i];
        final r = i + 2;
        sheet.getRangeByIndex(r, 1).setNumber(o.id.toDouble());
        sheet.getRangeByIndex(r, 2).setNumber(o.cartId.toDouble());
        sheet.getRangeByIndex(r, 3).setText(o.invoiceNumber);
        sheet.getRangeByIndex(r, 4).setText(o.referenceNumber ?? '');
        sheet.getRangeByIndex(r, 5).setNumber(o.totalAmount);
        sheet.getRangeByIndex(r, 6).setNumber(o.discountAmount);
        sheet.getRangeByIndex(r, 7).setText(o.discountType ?? '');
        sheet.getRangeByIndex(r, 8).setNumber(o.finalAmount);
        sheet.getRangeByIndex(r, 9).setText(o.customerName ?? '');
        sheet.getRangeByIndex(r, 10).setText(o.customerEmail ?? '');
        sheet.getRangeByIndex(r, 11).setText(o.customerPhone ?? '');
        sheet.getRangeByIndex(r, 12).setText(o.customerGender ?? '');
        sheet.getRangeByIndex(r, 13).setNumber(o.cashAmount);
        sheet.getRangeByIndex(r, 14).setNumber(o.creditAmount);
        sheet.getRangeByIndex(r, 15).setNumber(o.cardAmount);
        sheet.getRangeByIndex(r, 16).setNumber(o.onlineAmount);
        sheet.getRangeByIndex(r, 17).setText(o.createdAt.toIso8601String());
        sheet.getRangeByIndex(r, 18).setText(o.status);
        sheet.getRangeByIndex(r, 19).setText(o.orderType);
        sheet.getRangeByIndex(r, 20).setText(o.deliveryPartner ?? '');
        sheet.getRangeByIndex(r, 21).setText(o.driverId?.toString() ?? '');
        sheet.getRangeByIndex(r, 22).setText(o.driverName ?? '');
      }

      final bytes = workbook.saveAsStream();
      workbook.dispose();

      // If another process (e.g. Excel) locks the file, avoid crashing flow.
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          await file.writeAsBytes(bytes, flush: true);
          return;
        } on FileSystemException {
          if (attempt == 2) {
            // Best-effort backup only; do not throw into UI/business flow.
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
      }
    } catch (_) {
      // Best-effort backup only; suppress failures.
    }
  }
}

