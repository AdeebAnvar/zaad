import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/presentation/day_closing/day_closing_summary.dart';

/// When payment totals and computed net sales disagree, append one JSON line so
/// support can inspect `Documents/ZaadPOS/local/day_closing_reconcile.log`.
const _amountTol = 0.02;

Future<void> appendDayClosingReconcileLogIfNeeded(DayClosingSummary s) async {
  if (s.excessAmount <= _amountTol && s.shortAmount <= _amountTol) return;
  try {
    final dir = await AppDirectories.local();
    final path = p.join(dir.path, _fileName());
    final paid = s.cashSale + s.cardSale + s.creditSale + s.onlineSale;
    final map = <String, Object?>{
      'atUtc': DateTime.now().toUtc().toIso8601String(),
      'grossTotal': s.grossTotal,
      'discountAgg': s.discount,
      'netTotal': s.netTotal,
      'cash': s.cashSale,
      'card': s.cardSale,
      'credit': s.creditSale,
      'online': s.onlineSale,
      'collectedSum': paid,
      'excessAmount': s.excessAmount,
      'shortAmount': s.shortAmount,
      'unpaidAmount': s.unpaidAmount,
      'openingCash': s.openingCash,
      'defaultOpeningCash': s.defaultOpeningCash,
    };
    final line = '${jsonEncode(map)}\n';
    final sink = File(path).openWrite(mode: FileMode.append);
    sink.write(line);
    await sink.flush();
    await sink.close();
  } catch (_) {
    // Never block UI on diagnostics.
  }
}

String _fileName() => 'day_closing_reconcile.log';
