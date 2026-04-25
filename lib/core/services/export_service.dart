import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  static const String _rootFolder = 'ZaadPOS';
  static const String _exportFolder = 'exports';

  Future<Directory> _exportDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _rootFolder, _exportFolder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _fileName(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'unsynced_orders_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}.xlsx';
  }

  Future<File?> exportUnsyncedOrderLogs(AppDatabase db) async {
    final logs = await db.ordersDao.getUnsyncedOrderLogs();
    if (logs.isEmpty) return null;

    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Unsynced Orders';
    sheet.getRangeByName('A1').setText('id');
    sheet.getRangeByName('B1').setText('created_at');
    sheet.getRangeByName('C1').setText('synced');
    sheet.getRangeByName('D1').setText('order_json');

    for (var i = 0; i < logs.length; i++) {
      final row = i + 2;
      final log = logs[i];
      sheet.getRangeByIndex(row, 1).setNumber(log.id.toDouble());
      sheet.getRangeByIndex(row, 2).setText(log.createdAt.toIso8601String());
      sheet.getRangeByIndex(row, 3).setText(log.synced ? 'true' : 'false');
      // Keep compact/valid JSON in export.
      final compact = jsonEncode(jsonDecode(log.orderJson));
      sheet.getRangeByIndex(row, 4).setText(compact);
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    final dir = await _exportDir();
    final file = File(p.join(dir.path, _fileName(DateTime.now())));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

