import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/network/network_print_result.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:image/image.dart' as img;
import 'package:pos/core/print/debug_receipt_preview.dart';
import 'package:pos/core/print/kot_kitchen_update_diff.dart';
import 'package:pos/core/print/receipt_preview_data.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/domain/models/branch_model.dart';

/// Handles KOT (per-kitchen) and final bill printing.
class PrintService {
  PrintService(this._db, this._itemRepo);

  final AppDatabase _db;
  final ItemRepository _itemRepo;

  static const int _defaultPort = 9100;
  static const Duration _connectionTimeout = Duration(seconds: 15);
  static const String _debugLogPath = r'c:\Users\adeeb\OneDrive\Desktop\pos\pos\debug-079196.log';

  static String get _currency => '${RuntimeAppSettings.currency} ';

  static int get _decimals => RuntimeAppSettings.decimalDigits;

  static String _fmtMoney(num v) => v.toStringAsFixed(_decimals);

  static Future<void> _dbg({
    required String runId,
    required String hypothesisId,
    required String location,
    required String message,
    required Map<String, Object?> data,
  }) async {
    final payload = <String, Object?>{
      'sessionId': '079196',
      'runId': runId,
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    try {
      await File(_debugLogPath).writeAsString(
        '${jsonEncode(payload)}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }

  /// Strip ₹ from any string (item names, notes, etc.) so printer receives ASCII-only.
  static String _sanitize(String s) => s.replaceAll('₹', 'Rs');

  /// Grep / logcat: `POS_PRINT`. One line before every job so support can match printer, size, payload hash.
  static void _logPrinterPayloadHeading({
    required String jobKind,
    required String printerLabel,
    required String connectionType,
    required String address,
    required int port,
    String? vendorId,
    String? productId,
    required List<int> bytes,
  }) {
    final safeLabel = printerLabel.replaceAll('|', '/').trim();
    final addr = address.trim();
    final target = connectionType == 'network'
        ? '$addr:$port'
        : connectionType == 'usb'
            ? 'usb:${addr.isNotEmpty ? addr : (vendorId ?? '')} vid=${vendorId ?? ''} pid=${productId ?? ''}'
            : 'ble:${addr.isNotEmpty ? addr : '—'}';
    final n = bytes.length;
    final headLen = n >= 48 ? 48 : n;
    final headHex = headLen == 0 ? '' : bytes.sublist(0, headLen).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final sha = n == 0 ? 'empty' : sha256.convert(bytes).toString();
    final line = 'POS_PRINT | job=$jobKind | printer=$safeLabel | conn=$connectionType | target=$target | bytes=$n | sha256=$sha | headHex=$headHex';
    debugPrint(line);
    developer.log(line, name: 'POS_PRINT');
  }

  /// Grep / logcat: `POS_PRINT_ITEMS`. Logs each receipt row even when printer is not configured.
  static void _logReceiptLinesPreview({
    required int orderId,
    required int cartId,
    required String source,
    required List<_PrintLine> lines,
  }) {
    final head = 'POS_PRINT_ITEMS | orderId=$orderId | cartId=$cartId | source=$source | count=${lines.length}';
    debugPrint(head);
    developer.log(head, name: 'POS_PRINT_ITEMS');
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      var name = l.itemName.trim();
      if (l.variantName != null && l.variantName!.trim().isNotEmpty) {
        name = '$name (${l.variantName!.trim()})';
      }
      if (l.toppingInfo != null && l.toppingInfo!.trim().isNotEmpty) {
        name = '$name + ${l.toppingInfo!.trim()}';
      }
      final line = 'POS_PRINT_ITEMS | idx=${i + 1} | qty=${l.quantity} | unit=${_fmtMoney(l.unitPrice)} | total=${_fmtMoney(l.total)} | item=${_sanitize(name)}';
      debugPrint(line);
      developer.log(line, name: 'POS_PRINT_ITEMS');
    }
  }

  /// Grep / logcat: `POS_PRINT_ITEMS`. Logs KOT lines grouped by kitchen target.
  static void _logKotLinesPreview({
    required String job,
    required String kitchenKey,
    required List<_PrintLine> lines,
  }) {
    final head = 'POS_PRINT_ITEMS | job=$job | kitchen=$kitchenKey | count=${lines.length}';
    debugPrint(head);
    developer.log(head, name: 'POS_PRINT_ITEMS');
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      var name = l.itemName.trim();
      if (l.variantName != null && l.variantName!.trim().isNotEmpty) {
        name = '$name (${l.variantName!.trim()})';
      }
      final top = l.toppingInfo?.trim();
      if (top != null && top.isNotEmpty) {
        name = '$name + $top';
      }
      final line = 'POS_PRINT_ITEMS | job=$job | kitchen=$kitchenKey | idx=${i + 1} | qty=${l.quantity} | total=${_fmtMoney(l.total)} | item=${_sanitize(name)}';
      debugPrint(line);
      developer.log(line, name: 'POS_PRINT_ITEMS');
    }
  }

  static List<String> _dedupeWrappedLines(List<String> lines) {
    final seen = <String>{};
    final out = <String>[];
    for (final l in lines) {
      final k = l.trim().toLowerCase();
      if (k.isEmpty) continue;
      if (seen.add(k)) out.add(l.trim());
    }
    return out;
  }

  static List<String> _wrapReceiptLine(String text, int maxChars) {
    final t = text.trim();
    if (t.isEmpty) return const [''];
    if (t.length <= maxChars) return [t];
    final words = t.split(RegExp(r'\s+'));
    final lines = <String>[];
    var cur = '';
    for (final w in words) {
      if (w.isEmpty) continue;
      if (cur.isEmpty) {
        cur = w;
      } else if (cur.length + 1 + w.length <= maxChars) {
        cur = '$cur $w';
      } else {
        lines.add(cur);
        cur = w;
      }
    }
    if (cur.isNotEmpty) lines.add(cur);
    return lines;
  }

  static String _orderTypeLabel(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    return switch (s) {
      'take_away' => 'Take away',
      'dine_in' => 'Dine in',
      'delivery' => 'Delivery',
      _ => s.isEmpty
          ? ''
          : s.replaceAll('_', ' ').split(' ').map((w) {
              if (w.isEmpty) return w;
              return w[0].toUpperCase() + w.substring(1);
            }).join(' '),
    };
  }

  static ({double netBeforeVat, double vatAmount}) _vatBreakdown(double totalInclusive, BranchModel? branch) {
    if (branch == null) return (netBeforeVat: totalInclusive, vatAmount: 0.0);
    final mode = branch.vat.trim().toLowerCase();
    final vp = branch.vatPercent;
    final pct = vp is num ? vp.toDouble() : double.tryParse('$vp') ?? 0.0;
    if (mode == 'no_vat' || pct <= 0) {
      return (netBeforeVat: totalInclusive, vatAmount: 0.0);
    }
    final divisor = 1 + pct / 100.0;
    final net = totalInclusive / divisor;
    return (netBeforeVat: net, vatAmount: totalInclusive - net);
  }

  static ({String label, double amount}) _discountLineForReceipt(Order order) {
    final type = (order.discountType ?? '').trim().toLowerCase();
    final raw = order.discountAmount;
    if (raw <= 0.009) {
      return (label: 'Discount:', amount: 0.0);
    }
    if (type == 'percentage') {
      final pct = raw.clamp(0, 100).toDouble();
      final computed = (order.totalAmount * pct / 100).clamp(0, order.totalAmount).toDouble();
      return (label: 'Discount (${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 2)}%):', amount: computed);
    }
    return (label: 'Discount (Amount):', amount: raw.clamp(0, order.totalAmount).toDouble());
  }

  static ({String label, double amount})? _offerLineForReceipt(Order order) {
    final meta = order.hubMetadata;
    if (meta == null || meta.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(meta);
      if (decoded is! Map) return null;
      final root = Map<String, dynamic>.from(decoded);
      final rawOffer = root['applied_offer'];
      if (rawOffer is! Map) return null;
      final offer = Map<String, dynamic>.from(rawOffer);
      final amount = (offer['discountAmount'] as num?)?.toDouble() ??
          (double.tryParse(offer['discountAmount']?.toString() ?? '') ?? 0.0);
      if (amount <= 0.009) return null;
      final name = offer['name']?.toString().trim() ?? '';
      final label = name.isNotEmpty ? 'Offer ($name):' : 'Offer:';
      return (label: label, amount: amount.clamp(0, order.totalAmount).toDouble());
    } catch (_) {
      return null;
    }
  }

  /// Paid sale: completed, or payment lines cover the payable (e.g. delivery still `pending`).
  static bool _receiptShowsPaid(Order order, double totalPayable, double paidSum) {
    final st = order.status.trim().toLowerCase();
    if (st == 'cancelled') return false;
    if (st == 'completed') return true;
    if (totalPayable <= 0.009) return false;
    return paidSum + 0.02 >= totalPayable;
  }

  /// Prefer visible-catalog item; fall back to raw row so print routing ([Item.kitchenId]) works
  /// when the category was hidden from POS but cart lines still reference the item.
  Future<Item?> _itemRowForPrint(int itemId) async {
    final visible = await _itemRepo.fetchItemByIdFromLocal(itemId);
    if (visible != null) return visible;
    return _db.itemDao.getItemById(itemId);
  }

  Future<({String ip, int port, String kitchenLabel})?> _firstNonBillKitchenPrinter() async {
    final fromTable = await _db.itemDao.getAllKitchenPrinters();
    for (final kp in fromTable) {
      if (kp.kitchenId == 0) continue;
      final ip = kp.printerIp.trim();
      if (ip.isEmpty) continue;
      final port = kp.printerPort > 0 ? kp.printerPort : _defaultPort;
      final k = await _db.itemDao.getKitchenById(kp.kitchenId);
      var label = (k?.name ?? '').trim();
      if (label.isEmpty) label = 'Kitchen ${kp.kitchenId}';
      return (ip: kp.printerIp, port: port, kitchenLabel: label);
    }
    final kitchens = await _db.itemDao.getAllKitchens();
    for (final k in kitchens) {
      final ip = (k.printerIp ?? '').trim();
      if (ip.isEmpty) continue;
      final port = k.printerPort > 0 ? k.printerPort : _defaultPort;
      final label = k.name.trim().isEmpty ? 'Kitchen ${k.id}' : k.name.trim();
      return (ip: k.printerIp!, port: port, kitchenLabel: label);
    }
    return null;
  }

  Future<({String ip, int port, String kitchenLabel})?> _resolvePrinterForKitchenBucket(int kitchenId) async {
    if (kitchenId == 0) {
      final bill = await _db.itemDao.getBillPrinter();
      if (bill != null && bill.printerIp.trim().isNotEmpty) {
        final p = bill.printerPort > 0 ? bill.printerPort : _defaultPort;
        return (ip: bill.printerIp, port: p, kitchenLabel: 'General');
      }
      final fb = await _firstNonBillKitchenPrinter();
      if (fb != null && kDebugMode) {
        debugPrint(
          'PrintService: Bill printer unset; routing unassigned KOT lines to kitchen "${fb.kitchenLabel}"',
        );
      }
      return fb;
    }

    final kitchen = await _db.itemDao.getKitchenById(kitchenId);
    String? printerIp;
    var printerPort = _defaultPort;
    final kPrinterIp = kitchen?.printerIp?.trim();
    if (kitchen != null && kPrinterIp != null && kPrinterIp.isNotEmpty) {
      printerIp = kitchen.printerIp;
      printerPort = kitchen.printerPort > 0 ? kitchen.printerPort : _defaultPort;
    } else {
      final kitchenPrinter = await _db.itemDao.getPrinterByKitchenId(kitchenId);
      if (kitchenPrinter != null && kitchenPrinter.printerIp.trim().isNotEmpty) {
        printerIp = kitchenPrinter.printerIp;
        printerPort = kitchenPrinter.printerPort > 0 ? kitchenPrinter.printerPort : _defaultPort;
      }
    }
    if (printerIp == null || printerIp.trim().isEmpty) return null;
    final nm = kitchen?.name.trim();
    final label = (nm != null && nm.isNotEmpty) ? nm : 'Kitchen';
    return (ip: printerIp.trim(), port: printerPort, kitchenLabel: label);
  }

  /// KOT when [cartItems] is empty still works if [order] is set (snapshot in OrderLog / hubMetadata).
  Future<List<_PrintLine>> _kotLinesFromCartOrOrder(List<CartItem> cartItems, Order? order) async {
    if (cartItems.isNotEmpty) {
      return _buildPrintLines(cartItems);
    }
    if (order == null) return [];
    var lines = await _fallbackPrintLinesWhenCartEmpty(order);
    if (lines.isEmpty) {
      final payable = order.finalAmount > 0.009 ? order.finalAmount : order.totalAmount;
      if (payable > 0.009) {
        lines = [
          _PrintLine(
            itemName: _sanitize('Sale (detail unavailable locally)'),
            quantity: 1,
            unitPrice: payable,
            total: payable,
          ),
        ];
      }
    }
    return lines;
  }

  Future<img.Image?> _tryLoadBranchLogo(BranchModel? branch) async {
    if (branch == null || !RuntimeAppSettings.printImageInBillEnabled) return null;
    final path = branch.localImage.trim().isNotEmpty ? branch.localImage.trim() : '';
    if (path.isEmpty) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      const maxW = 700;
      if (decoded.width > maxW) {
        return img.copyResize(decoded, width: maxW, interpolation: img.Interpolation.linear);
      }
      return decoded;
    } catch (e) {
      if (kDebugMode) debugPrint('PrintService: logo decode failed: $e');
      return null;
    }
  }

  /// Groups cart items by kitchen and prints KOT to each kitchen's printer.
  /// [referenceNumber] e.g. table number or order ref.
  /// [invoiceNumber] used on the slip as Receipt no.; falls back to [referenceNumber] if empty.
  /// Returns list of printer labels that failed (working printers still print).
  Future<List<String>> printKOTPerKitchen({
    required List<CartItem> cartItems,
    Order? order,
    required String referenceNumber,
    String? invoiceNumber,
    int? branchId,
    DateTime? orderedAt,
  }) async {
    final failed = <String>[];
    final previewDocs = <String>[];
    final sessionBranch = branchId ?? (await _db.sessionDao.getActiveSession())?.branchId ?? 1;
    final branchModel = await _db.branchesDao.getBranchById(sessionBranch);
    final resolvedBranchName = _sanitize((branchModel?.branchName ?? '').trim());
    final refRaw = referenceNumber.trim();
    final invRaw = (invoiceNumber ?? '').trim();
    final orderDate = orderedAt ?? DateTime.now();

    final lines = await _kotLinesFromCartOrOrder(cartItems, order);
    if (lines.isEmpty) return failed;

    final byKitchen = <int?, List<_PrintLine>>{};
    for (final line in lines) {
      byKitchen.putIfAbsent(line.kitchenId, () => []).add(line);
    }
    if (kDebugMode) {
      for (final entry in byKitchen.entries) {
        final kitchenId = entry.key ?? 0;
        final kLabel = kitchenId == 0 ? 'GENERAL(0)' : '$kitchenId';
        _logKotLinesPreview(
          job: 'KOT',
          kitchenKey: kLabel,
          lines: entry.value,
        );
      }
    }

    for (final entry in byKitchen.entries) {
      final kitchenId = entry.key ?? 0;
      final resolved = await _resolvePrinterForKitchenBucket(kitchenId);
      final fallbackKitchenName = kitchenId == 0 ? 'General' : 'Kitchen $kitchenId';
      final previewKitchenName = resolved?.kitchenLabel ?? fallbackKitchenName;
      previewDocs.addAll(
        _buildKotPreviewLines(
          items: entry.value,
          branchName: resolvedBranchName,
          kitchenName: previewKitchenName,
          referenceNumber: refRaw,
          invoiceNumber: invRaw,
          orderedAt: orderDate,
        ),
      );
      previewDocs.add('');
      previewDocs.add('=' * 42);
      previewDocs.add('');

      if (resolved == null) {
        if (kDebugMode) {
          debugPrint('PrintService: No printer configured for kitchen $kitchenId');
        }
        continue;
      }
      final printerIp = resolved.ip;
      final printerPort = resolved.port;
      final kitchenName = resolved.kitchenLabel;
      final printerLabel = 'Kitchen "$kitchenName" printer';

      try {
        final bytes = await _generateKOTTicket(
          items: entry.value,
          branchName: resolvedBranchName,
          kitchenName: kitchenName,
          referenceNumber: refRaw,
          invoiceNumber: invRaw,
          orderedAt: orderDate,
        );
        final (address, vendorId, productId, connType) = _decodeAddress(printerIp);
        await _sendToPrinter(
          jobKind: 'KOT',
          address: address,
          port: printerPort,
          bytes: bytes,
          printerLabel: printerLabel,
          connectionType: connType,
          vendorId: vendorId,
          productId: productId,
        );
      } catch (e, st) {
        debugPrint('PrintService: KOT printer failed [$printerLabel]: $e');
        debugPrint('PrintService: stack trace:\n$st');
        failed.add(printerLabel);
      }
    }
    if (kDebugMode && previewDocs.isNotEmpty) {
      scheduleDebugReceiptPreview(
        _buildRawTicketPreview(
          title: 'KOT preview (debug)',
          subtitle: 'Thermal layout · 80mm · all kitchen slips',
          lines: previewDocs,
        ),
      );
    }
    return failed;
  }

  /// Kitchen slips for edits: only quantity deltas (**CANCELLED** / **UPDATED**).
  /// [orderTypeRaw] is `Orders.orderType` (`take_away`, `dine_in`, `delivery`).
  Future<List<String>> printKOTUpdatePerKitchen({
    required List<KotKitchenUpdateRow> rows,
    required String? orderTypeRaw,
    required String referenceNumber,
    String? invoiceNumber,
    int? branchId,
    DateTime? orderedAt,
  }) async {
    final failed = <String>[];
    final previewDocs = <String>[];
    if (rows.isEmpty) return failed;

    final sessionBranch = branchId ?? (await _db.sessionDao.getActiveSession())?.branchId ?? 1;
    final branchModel = await _db.branchesDao.getBranchById(sessionBranch);
    final resolvedBranchName = _sanitize((branchModel?.branchName ?? '').trim());
    final refRaw = referenceNumber.trim();
    final invRaw = (invoiceNumber ?? '').trim();
    final orderDate = orderedAt ?? DateTime.now();
    final orderTypeLabel = _orderTypeLabel(orderTypeRaw);

    final paired = <(KotKitchenUpdateRow, _PrintLine)>[];
    for (final r in rows) {
      final pls = await _buildPrintLines([r.lineForKitchen]);
      if (pls.isEmpty) continue;
      paired.add((r, pls.first));
    }
    if (paired.isEmpty) return failed;

    final byKitchen = <int?, List<(KotKitchenUpdateRow, _PrintLine)>>{};
    for (final p in paired) {
      final kid = p.$2.kitchenId;
      byKitchen.putIfAbsent(kid, () => []).add(p);
    }
    if (kDebugMode) {
      for (final entry in byKitchen.entries) {
        final kitchenId = entry.key ?? 0;
        final kLabel = kitchenId == 0 ? 'GENERAL(0)' : '$kitchenId';
        final preview = entry.value.map((e) => e.$2).toList();
        _logKotLinesPreview(
          job: 'KOT_UPDATE',
          kitchenKey: kLabel,
          lines: preview,
        );
      }
    }

    for (final entry in byKitchen.entries) {
      final kitchenId = entry.key ?? 0;

      final resolved = await _resolvePrinterForKitchenBucket(kitchenId);
      final fallbackKitchenName = kitchenId == 0 ? 'General' : 'Kitchen $kitchenId';
      final previewKitchenName = resolved?.kitchenLabel ?? fallbackKitchenName;
      previewDocs.addAll(
        _buildKotUpdatePreviewLines(
          pairs: entry.value,
          branchName: resolvedBranchName,
          kitchenName: previewKitchenName,
          referenceNumber: refRaw,
          invoiceNumber: invRaw,
          orderTypeLabel: orderTypeLabel,
          orderedAt: orderDate,
        ),
      );
      previewDocs.add('');
      previewDocs.add('=' * 42);
      previewDocs.add('');
      if (resolved == null) {
        if (kDebugMode) {
          debugPrint('PrintService: No printer configured for kitchen update $kitchenId');
        }
        continue;
      }
      final printerIp = resolved.ip;
      final printerPort = resolved.port;
      final kitchenName = resolved.kitchenLabel;
      final printerLabel = 'Kitchen "$kitchenName" printer (update)';

      try {
        final bytes = await _generateKOTUpdateTicket(
          pairs: entry.value,
          branchName: resolvedBranchName,
          kitchenName: kitchenName,
          referenceNumber: refRaw,
          invoiceNumber: invRaw,
          orderTypeLabel: orderTypeLabel,
          orderedAt: orderDate,
        );
        final (address, vendorId, productId, connType) = _decodeAddress(printerIp);
        await _sendToPrinter(
          jobKind: 'KOT_UPDATE',
          address: address,
          port: printerPort,
          bytes: bytes,
          printerLabel: printerLabel,
          connectionType: connType,
          vendorId: vendorId,
          productId: productId,
        );
      } catch (e, st) {
        debugPrint('PrintService: KOT update printer failed [$printerLabel]: $e');
        debugPrint('PrintService: stack trace:\n$st');
        failed.add(printerLabel);
      }
    }
    if (kDebugMode && previewDocs.isNotEmpty) {
      scheduleDebugReceiptPreview(
        _buildRawTicketPreview(
          title: 'KOT update preview (debug)',
          subtitle: 'Thermal layout · 80mm · all kitchen update slips',
          lines: previewDocs,
        ),
      );
    }
    return failed;
  }

  /// Prints final bill (customer receipt) with all items.
  /// Uses bill printer (kitchen_id=0).
  /// Returns list of printer labels that failed (working printers still print).
  /// When `cart_items` rows are missing locally, rebuild lines from cloud push snapshot JSON.
  Future<List<_PrintLine>> _fallbackPrintLinesWhenCartEmpty(Order order) async {
    final log = await _db.ordersDao.findLatestOrderLogByLocalOrderId(order.id);
    if (log != null) {
      try {
        final decoded = jsonDecode(log.orderJson);
        if (decoded is Map<String, dynamic>) {
          final items = decoded['items'];
          if (items is List && items.isNotEmpty) {
            final from = _printLinesFromSnapshotItemsList(items);
            if (from.isNotEmpty) return from;
          }
        }
      } catch (_) {}
    }

    final hm = order.hubMetadata;
    if (hm != null && hm.trim().isNotEmpty) {
      try {
        final root = jsonDecode(hm);
        if (root is Map<String, dynamic>) {
          final meta = root['metadata'];
          if (meta is Map<String, dynamic>) {
            final cl = meta['cart_lines'];
            if (cl is List && cl.isNotEmpty) {
              final from = _printLinesFromSnapshotItemsList(cl);
              if (from.isNotEmpty) return from;
            }
          }
          final cl2 = root['cart_lines'];
          if (cl2 is List && cl2.isNotEmpty) {
            final from = _printLinesFromSnapshotItemsList(cl2);
            if (from.isNotEmpty) return from;
          }
          final hubItems = root['items'];
          if (hubItems is List && hubItems.isNotEmpty) {
            final from = _printLinesFromSnapshotItemsList(hubItems);
            if (from.isNotEmpty) return from;
          }
          final md = root['metadata'];
          if (md is Map<String, dynamic>) {
            final flutter = md['flutter'];
            if (flutter is Map<String, dynamic>) {
              final cartIdRaw = flutter['cart_id'];
              final cartId = cartIdRaw is int ? cartIdRaw : int.tryParse('$cartIdRaw');
              if (cartId != null && cartId > 0) {
                final byFlutterCart = await _db.cartsDao.getItemsByCart(cartId);
                if (byFlutterCart.isNotEmpty) {
                  final from = await _buildPrintLines(byFlutterCart);
                  if (from.isNotEmpty) return from;
                }
              }
            }
          }
        }
      } catch (_) {}
    }
    return [];
  }

  List<_PrintLine> _printLinesFromSnapshotItemsList(List<dynamic> items) {
    final out = <_PrintLine>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final qtyRaw = m['quantity'] ?? m['qty'];
      final qty = qtyRaw is int ? qtyRaw : (qtyRaw is num ? qtyRaw.toInt() : int.tryParse('$qtyRaw') ?? 1);
      if (qty <= 0) continue;
      final totalRaw = m['total'];
      var total = totalRaw is num ? totalRaw.toDouble() : double.tryParse('$totalRaw') ?? 0.0;
      if (total <= 0) {
        final centsRaw = m['unitPriceCents'] ?? m['unit_price_cents'];
        final cents = centsRaw is num ? centsRaw.round() : int.tryParse('$centsRaw');
        if (cents != null && cents > 0) {
          total = cents * qty / 100.0;
        }
      }
      var name = '${m['item_name'] ?? m['itemName'] ?? m['name'] ?? ''}'.trim();
      if (name.isEmpty) name = 'Item';

      final unit = total / qty;

      String? toppingInfo;
      List<(String name, num qty)>? kotToppings;
      final notesRaw = m['notes'];
      final notesStr = notesRaw is String ? notesRaw : null;
      final toppingsData = _decodeToppingsJson(notesStr);
      if (toppingsData != null && toppingsData.isNotEmpty) {
        toppingInfo = toppingsData.map((t) => '${t['name'] ?? ''} x${t['qty'] ?? 1}').join(', ');
        kotToppings = toppingsData
            .map((t) {
              final n = '${t['name'] ?? ''}'.trim();
              final qRaw = t['qty'];
              final qNum = qRaw is num ? qRaw : num.tryParse('$qRaw');
              final q = qNum ?? 1;
              return (n, q);
            })
            .where((e) => e.$1.isNotEmpty)
            .toList();
        if (kotToppings.isEmpty) kotToppings = null;
      }

      out.add(_PrintLine(
        itemName: _sanitize(name),
        variantName: null,
        toppingInfo: toppingInfo?.isNotEmpty == true ? _sanitize(toppingInfo!) : null,
        kotToppings: kotToppings,
        quantity: qty,
        unitPrice: unit,
        total: total,
        notes: notesStr,
        kitchenId: null,
        kitchenName: null,
      ));
    }
    return out;
  }

  Future<List<String>> printFinalBill({
    required Order order,
    required List<CartItem> cartItems,

    /// When true (e.g. customer bill from order log), receipt shows a settled-bill header.
    bool settledBill = false,

    /// When true, print header indicates edited bill.
    bool updatedOrder = false,

    /// Matches **Invoice print** in payment: tax-invoice title vs simple receipt.
    /// Reprints from logs default this to true via [printFinalBill] defaults at call sites.
    bool asTaxInvoice = true,
  }) async {
    final failed = <String>[];
    // #region agent log
    await _dbg(
      runId: 'pre-fix',
      hypothesisId: 'H1',
      location: 'print_service.dart:printFinalBill:entry',
      message: 'Entered printFinalBill',
      data: {
        'orderId': order.id,
        'orderCartId': order.cartId,
        'cartItemsArgCount': cartItems.length,
      },
    );
    // #endregion
    // Call sites sometimes pass an empty list after UI cleared state; lines still live on order.cartId.
    var effectiveCart = cartItems;
    if (effectiveCart.isEmpty) {
      effectiveCart = await _db.cartsDao.getItemsByCart(order.cartId);
    }
    var lines = await _buildPrintLines(effectiveCart);
    if (lines.isEmpty) {
      lines = await _fallbackPrintLinesWhenCartEmpty(order);
    }
    if (lines.isEmpty) {
      final payable = order.finalAmount > 0.009 ? order.finalAmount : order.totalAmount;
      if (payable > 0.009) {
        lines = [
          _PrintLine(
            itemName: _sanitize('Sale (detail unavailable locally)'),
            quantity: 1,
            unitPrice: payable,
            total: payable,
          ),
        ];
      } else {
        lines = [
          _PrintLine(
            itemName: _sanitize('No item lines found (cart/log metadata missing)'),
            quantity: 1,
            unitPrice: 0,
            total: 0,
          ),
        ];
      }
    }
    // #region agent log
    await _dbg(
      runId: 'pre-fix',
      hypothesisId: 'H2',
      location: 'print_service.dart:printFinalBill:resolved-lines',
      message: 'Resolved effective cart and receipt lines',
      data: {
        'orderId': order.id,
        'effectiveCartCount': effectiveCart.length,
        'linesCount': lines.length,
      },
    );
    // #endregion
    if (kDebugMode) {
      final src = effectiveCart.isNotEmpty ? 'cart_rows' : 'fallback_rows';
      debugPrint(
        'PrintService: RECEIPT lines=${lines.length} source=$src orderId=${order.id} cartId=${order.cartId}',
      );
      _logReceiptLinesPreview(
        orderId: order.id,
        cartId: order.cartId,
        source: src,
        lines: lines,
      );
    }
    final billPrinter = await _db.itemDao.getBillPrinter();
    final noBillPrinter = billPrinter == null || billPrinter.printerIp.trim().isEmpty;

    if (noBillPrinter && !kDebugMode) {
      // #region agent log
      await _dbg(
        runId: 'pre-fix',
        hypothesisId: 'H3',
        location: 'print_service.dart:printFinalBill:no-printer',
        message: 'Bill printer missing while lines were already resolved',
        data: {
          'orderId': order.id,
          'linesCount': lines.length,
        },
      );
      // #endregion
      debugPrint('PrintService: No bill printer configured');
      return failed;
    }

    const printerLabel = 'Bill printer';
    try {
      final bytes = await _generateFinalBillTicket(
        order: order,
        lines: lines,
        settledBill: settledBill,
        updatedOrder: updatedOrder,
        asTaxInvoice: asTaxInvoice,
      );
      // #region agent log
      await _dbg(
        runId: 'pre-fix',
        hypothesisId: 'H4',
        location: 'print_service.dart:printFinalBill:bytes-ready',
        message: 'Generated receipt ticket bytes',
        data: {
          'orderId': order.id,
          'linesCount': lines.length,
          'bytesCount': bytes.length,
        },
      );
      // #endregion
      if (kDebugMode) {
        final preview = await _buildReceiptPreviewData(
          order: order,
          lines: lines,
          settledBill: settledBill,
          updatedOrder: updatedOrder,
          asTaxInvoice: asTaxInvoice,
        );
        scheduleDebugReceiptPreview(preview);
        if (noBillPrinter) {
          debugPrint('PrintService: No bill printer — debug receipt preview shown');
          return failed;
        }
      }

      final (address, vendorId, productId, connType) = _decodeAddress(billPrinter!.printerIp);
      await _sendToPrinter(
        jobKind: 'RECEIPT',
        address: address,
        port: billPrinter.printerPort,
        bytes: bytes,
        printerLabel: printerLabel,
        connectionType: connType,
        vendorId: vendorId,
        productId: productId,
      );
    } catch (e, st) {
      debugPrint('PrintService: Bill printer failed [$printerLabel]: $e');
      debugPrint('PrintService: stack trace:\n$st');
      failed.add(printerLabel);
    }
    return failed;
  }

  Future<ReceiptPreviewData> _buildReceiptPreviewData({
    required Order order,
    required List<_PrintLine> lines,
    required bool settledBill,
    required bool updatedOrder,
    required bool asTaxInvoice,
  }) async {
    final branch = await _db.branchesDao.getBranchById(order.branchId);
    final logoImg = await _tryLoadBranchLogo(branch);
    Uint8List? logoPng;
    if (logoImg != null) {
      logoPng = Uint8List.fromList(img.encodePng(logoImg));
    }
    return ReceiptPreviewData.receipt(
      previewTitle: 'Receipt preview (debug)',
      previewSubtitle: 'Thermal layout · 80mm · same content as print',
      order: order,
      lines: lines
          .map(
            (l) => ReceiptPreviewLine(
              itemName: l.itemName,
              variantName: l.variantName,
              toppingInfo: l.toppingInfo,
              quantity: l.quantity,
              unitPrice: l.unitPrice,
              total: l.total,
            ),
          )
          .toList(),
      branch: branch,
      logoPngBytes: logoPng,
      settledBill: settledBill,
      updatedOrder: updatedOrder,
      asTaxInvoice: asTaxInvoice,
    );
  }

  ReceiptPreviewData _buildRawTicketPreview({
    required String title,
    required String subtitle,
    required List<String> lines,
  }) {
    return ReceiptPreviewData.rawTicket(
      previewTitle: title,
      previewSubtitle: subtitle,
      rawLines: lines,
    );
  }

  List<String> _buildKotPreviewLines({
    required List<_PrintLine> items,
    required String branchName,
    required String kitchenName,
    required String referenceNumber,
    required String invoiceNumber,
    required DateTime orderedAt,
  }) {
    final out = <String>[];
    final safeBranch = branchName.trim();
    if (safeBranch.isNotEmpty) out.add(_sanitize(safeBranch));
    out.add('--- new order ---'.padLeft(28).padRight(42));
    out.add('Kitchen: ${_sanitize(kitchenName)}');
    _appendKotPreviewRefInvoice(out, referenceNumber: referenceNumber, invoiceNumber: invoiceNumber);
    out.add('');
    out.add('ITEM'.padRight(38) + 'QTY'.padLeft(4));
    out.add('-' * 42);
    for (final line in items) {
      out.addAll(_kotPreviewBlock(line));
    }
    out.add('-' * 42);
    out.add('');
    out.add('ordered date: ${RuntimeAppSettings.formatDateTime(orderedAt)}');
    return out;
  }

  List<String> _buildKotUpdatePreviewLines({
    required List<(KotKitchenUpdateRow, _PrintLine)> pairs,
    required String branchName,
    required String kitchenName,
    required String referenceNumber,
    required String invoiceNumber,
    required String orderTypeLabel,
    required DateTime orderedAt,
  }) {
    final out = <String>[];
    final safeBranch = branchName.trim();
    if (safeBranch.isNotEmpty) out.add(_sanitize(safeBranch));
    out.add('--- update order ---'.padLeft(28).padRight(42));
    out.add('Kitchen: ${_sanitize(kitchenName)}');
    if (orderTypeLabel.isNotEmpty) out.add(orderTypeLabel);
    _appendKotPreviewRefInvoice(out, referenceNumber: referenceNumber, invoiceNumber: invoiceNumber);
    out.add('');
    out.add('ITEM'.padRight(38) + 'QTY'.padLeft(4));
    out.add('-' * 42);
    for (final pair in pairs) {
      out.addAll(_kotPreviewBlock(pair.$2));
      out.add(pair.$1.isCancelled ? '- CANCELLED' : '- UPDATED');
      out.add('');
    }
    out.add('-' * 42);
    out.add('');
    out.add('ordered date: ${RuntimeAppSettings.formatDateTime(orderedAt)}');
    return out;
  }

  List<String> _buildDayClosingPreviewLines({
    required String title,
    required List<({String label, double amount})> rows,
  }) {
    final out = <String>[
      _sanitize(title.toUpperCase()),
      RuntimeAppSettings.formatDateTime(DateTime.now()),
      '',
      '-' * 42,
    ];
    for (final row in rows) {
      final label = _sanitize(row.label.toUpperCase());
      final amount = '$_currency${row.amount.toStringAsFixed(2)}';
      final left = label.length >= 30 ? label.substring(0, 30) : label.padRight(30);
      out.add(left + amount.padLeft(12));
    }
    out.add('-' * 42);
    return out;
  }

  List<String> _kotPreviewBlock(_PrintLine line) {
    final out = <String>[];
    var baseItem = _kotStripTaxVerbiage(line.itemName.trim());
    if (line.variantName != null && line.variantName!.trim().isNotEmpty) {
      baseItem += ' (${_kotStripTaxVerbiage(line.variantName!.trim())})';
    }
    out.addAll(_kotPreviewItemQty(baseItem, qtyStr: line.quantity.toString()));
    final tops = line.kotToppings;
    if (tops != null) {
      for (final t in tops) {
        final nm = _kotStripTaxVerbiage(t.$1.trim());
        if (nm.isEmpty) continue;
        out.addAll(_kotPreviewItemQty('  (+${_sanitize(nm)})', qtyStr: _kotFmtQty(t.$2)));
      }
    } else if (line.toppingInfo != null && line.toppingInfo!.trim().isNotEmpty) {
      out.add('  ${_sanitize(_kotPlainToppingInfo(line.toppingInfo!))}');
    }
    final lineNoteRaw = _lineNoteFromCartNotes(line.notes);
    final lineNote = lineNoteRaw != null && lineNoteRaw.isNotEmpty ? _kotStripTaxVerbiage(lineNoteRaw) : null;
    if (lineNote != null && lineNote.isNotEmpty) {
      out.addAll(_wrapReceiptLine('  Note: ${_sanitize(lineNote)}', 38));
    }
    return out;
  }

  List<String> _kotPreviewItemQty(String text, {required String qtyStr}) {
    final wrapped = _wrapReceiptLine(_sanitize(text), 38);
    final out = <String>[];
    for (var i = 0; i < wrapped.length; i++) {
      final left = wrapped[i];
      final leftCell = left.length >= 38 ? left.substring(0, 38) : left.padRight(38);
      out.add(leftCell + (i == 0 ? qtyStr : '').padLeft(4));
    }
    return out;
  }

  /// ESC/POS pulse to open cash drawer via the **bill printer** (same IP/USB as receipt).
  Future<List<String>> openCashDrawer({PosDrawer pin = PosDrawer.pin2}) async {
    final failed = <String>[];
    final billPrinter = await _db.itemDao.getBillPrinter();
    if (billPrinter == null || billPrinter.printerIp.isEmpty) {
      if (kDebugMode) debugPrint('PrintService: No bill printer configured for cash drawer');
      return failed;
    }

    const printerLabel = 'Cash drawer (bill printer)';
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      final bytes = generator.drawer(pin: pin);
      final (address, vendorId, productId, connType) = _decodeAddress(billPrinter.printerIp);
      await _sendToPrinter(
        jobKind: 'CASH_DRAWER',
        address: address,
        port: billPrinter.printerPort,
        bytes: bytes,
        printerLabel: printerLabel,
        connectionType: connType,
        vendorId: vendorId,
        productId: productId,
      );
    } catch (e, st) {
      debugPrint('PrintService: Cash drawer failed [$printerLabel]: $e');
      debugPrint('PrintService: stack trace:\n$st');
      failed.add(printerLabel);
    }
    return failed;
  }

  /// Prints a compact day-closing report to the bill printer.
  Future<List<String>> printDayClosingReport({
    required String title,
    required List<({String label, double amount})> rows,
  }) async {
    final failed = <String>[];
    final billPrinter = await _db.itemDao.getBillPrinter();
    final noBillPrinter = billPrinter == null || billPrinter.printerIp.isEmpty;
    if (noBillPrinter && !kDebugMode) {
      if (kDebugMode) debugPrint('PrintService: No bill printer configured');
      return failed;
    }

    const printerLabel = 'Bill printer';
    try {
      final bytes = await _generateDayClosingTicket(
        title: title,
        rows: rows,
      );
      if (kDebugMode) {
        scheduleDebugReceiptPreview(
          _buildRawTicketPreview(
            title: 'Day closing preview (debug)',
            subtitle: 'Thermal layout · 80mm · same content as print',
            lines: _buildDayClosingPreviewLines(title: title, rows: rows),
          ),
        );
        if (noBillPrinter) {
          debugPrint('PrintService: No bill printer — day closing preview shown');
          return failed;
        }
      }
      final (address, vendorId, productId, connType) = _decodeAddress(billPrinter!.printerIp);
      await _sendToPrinter(
        jobKind: 'DAY_CLOSING',
        address: address,
        port: billPrinter.printerPort,
        bytes: bytes,
        printerLabel: printerLabel,
        connectionType: connType,
        vendorId: vendorId,
        productId: productId,
      );
    } catch (e, st) {
      debugPrint('PrintService: Day closing printer failed [$printerLabel]: $e');
      debugPrint('PrintService: stack trace:\n$st');
      failed.add(printerLabel);
    }
    return failed;
  }

  Future<List<_PrintLine>> _buildPrintLines(List<CartItem> cartItems) async {
    final lines = <_PrintLine>[];
    for (final ci in cartItems) {
      final item = await _itemRowForPrint(ci.itemId);
      ItemVariant? variant;
      if (ci.itemVariantId != null) {
        variant = await _itemRepo.fetchVariantById(ci.itemVariantId!);
      }
      ItemTopping? topping;
      if (ci.itemToppingId != null) {
        topping = await _itemRepo.fetchToppingById(ci.itemToppingId!);
      }

      String? toppingInfo;
      List<(String name, num qty)>? kotToppings;
      final toppingsData = _decodeToppingsJson(ci.notes);
      if (toppingsData != null && toppingsData.isNotEmpty) {
        toppingInfo = toppingsData.map((t) => '${t['name'] ?? ''} x${t['qty'] ?? 1}').join(', ');
        kotToppings = toppingsData
            .map((t) {
              final n = '${t['name'] ?? ''}'.trim();
              final qRaw = t['qty'];
              final qty = qRaw is num ? qRaw : num.tryParse('$qRaw');
              final q = qty ?? 1;
              return (n, q);
            })
            .where((e) => e.$1.isNotEmpty)
            .toList();
        if (kotToppings.isEmpty) kotToppings = null;
      } else if (topping != null) {
        toppingInfo = '${topping.name} (+$_currency${topping.price.toStringAsFixed(0)})';
        final tn = topping.name.trim();
        kotToppings = tn.isNotEmpty ? [(tn, ci.quantity)] : null;
      }

      lines.add(_PrintLine(
        itemName: _sanitize(
          ci.itemName.isNotEmpty ? ci.itemName : (item?.name ?? 'Unknown'),
        ),
        variantName: variant?.name != null ? _sanitize(variant!.name) : null,
        toppingInfo: toppingInfo?.isNotEmpty == true ? _sanitize(toppingInfo!) : null,
        kotToppings: kotToppings,
        quantity: ci.quantity,
        unitPrice: (variant?.price ?? item?.price ?? 0),
        total: ci.total,
        notes: ci.notes,
        kitchenId: item?.kitchenId,
        kitchenName: item?.kitchenName,
      ));
    }
    return lines;
  }

  List<Map<String, dynamic>>? _decodeToppingsJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      if (decoded is Map) {
        final t = decoded['toppings'];
        if (t is List) {
          return t.cast<Map<String, dynamic>>();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _lineNoteFromCartNotes(String? notes) {
    if (notes == null || notes.isEmpty) return null;
    final t = notes.trimLeft();
    if (t.startsWith('[')) return null;
    if (t.startsWith('{')) {
      try {
        final d = jsonDecode(notes);
        if (d is Map) {
          final n = d['lineNote'] ??
              d['line_note'] ??
              d['note'] ??
              d['notes'] ??
              d['remarks'] ??
              d['instruction'] ??
              d['instructions'];
          if (n is String && n.trim().isNotEmpty) return n.trim();
          if (n != null && n is! Map && n is! List) {
            final s = n.toString().trim();
            if (s.isNotEmpty) return s;
          }
        }
      } catch (_) {
        return null;
      }
      return null;
    }
    return notes.trim();
  }

  /// KOT: no prices on topping fallback lines; also strip tax wording ([_kotStripTaxVerbiage]).
  String _kotPlainToppingInfo(String toppingInfo) {
    final noPrice = toppingInfo.replaceAll(RegExp(r'\s*\(\+[^)]*\)'), '').trim();
    return _kotStripTaxVerbiage(noPrice);
  }

  /// Kitchen tickets never show VAT phrasing (final bill still has full tax breakdown).
  String _kotStripTaxVerbiage(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;
    s = s.replaceAll(RegExp(r'\(?\s*inclusive\s+of\s+VAT\s*\)?', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\(?\s*incl\.?\s*(of\s*)?VAT\s*\)?', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\(?\s*VAT\s*incl\.?\s*\)?', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\(?\s*excl\.?\s*(of\s*)?VAT\s*\)?', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\(?\s*exclusive\s+of\s+VAT\s*\)?', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\btax\s+invoice\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\bVAT\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\(\s*\)'), '');
    return s.replaceAll(RegExp(r'\s{2,}'), ' ').replaceAll(RegExp(r'\s+,'), ',').trim();
  }

  void _appendKotPreviewRefInvoice(
    List<String> out, {
    required String referenceNumber,
    required String invoiceNumber,
  }) {
    final ref = referenceNumber.trim();
    final inv = invoiceNumber.trim();
    if (ref.isNotEmpty && inv.isNotEmpty && ref == inv) {
      out.add('Ref / Receipt: ${_sanitize(ref)}');
      return;
    }
    if (ref.isNotEmpty) {
      out.add('Reference: ${_sanitize(ref)}');
    }
    if (inv.isNotEmpty) {
      out.add('Receipt no: ${_sanitize(inv)}');
    } else if (ref.isEmpty) {
      out.add('Receipt no: —');
    }
  }

  List<int> _kotThermalRefInvoiceHeader(
    Generator generator, {
    required String referenceNumber,
    required String invoiceNumber,
    bool referenceBold = true,
  }) {
    List<int> chunk = [];
    final ref = referenceNumber.trim();
    final inv = invoiceNumber.trim();
    final refStyle = referenceBold ? const PosStyles(bold: true, align: PosAlign.left) : const PosStyles(align: PosAlign.left);
    if (ref.isNotEmpty && inv.isNotEmpty && ref == inv) {
      chunk += generator.text(
        'Ref / Receipt: ${_sanitize(ref)}',
        styles: const PosStyles(align: PosAlign.left),
      );
      return chunk;
    }
    if (ref.isNotEmpty) {
      chunk += generator.text('Reference: ${_sanitize(ref)}', styles: refStyle);
    }
    if (inv.isNotEmpty) {
      chunk += generator.text(
        'Receipt no: ${_sanitize(inv)}',
        styles: const PosStyles(align: PosAlign.left),
      );
    } else if (ref.isEmpty) {
      chunk += generator.text(
        'Receipt no: —',
        styles: const PosStyles(align: PosAlign.left),
      );
    }
    return chunk;
  }

  static String _kotFmtQty(num q) => ((q - q.round()).abs() < 1e-9) ? q.round().toString() : '$q'.trimRight();

  /// Item / qty columns; qty is printed only on the first continuation line when the name wraps.
  /// Receipt line items: **Item | Qty | Price | Total** (80mm row widths sum to 12).
  void _billEmitItemTableRow(
    Generator generator,
    List<int> bytes,
    String itemText,
    int quantity,
    String unitPriceStr,
    String lineTotalStr,
  ) {
    // Print in strict table layout: Qty | Product | Price | Subtotal.
    // Use addAll() so bytes are appended to the same caller buffer.
    const itemWrapChars = 20;
    final wrapped = _wrapReceiptLine(itemText.trim(), itemWrapChars);
    final u = _sanitize(unitPriceStr);
    final t = _sanitize(lineTotalStr);
    // #region agent log
    _dbg(
      runId: 'pre-fix',
      hypothesisId: 'H6',
      location: 'print_service.dart:_billEmitItemTableRow:entry',
      message: 'Receipt row layout inputs before generator.row',
      data: {
        'itemText': itemText,
        'quantity': quantity,
        'unitPriceStr': unitPriceStr,
        'lineTotalStr': lineTotalStr,
        'wrappedCount': wrapped.length,
      },
    );
    // #endregion
    for (var i = 0; i < wrapped.length; i++) {
      final qtyCell = i == 0 ? '$quantity' : '';
      final productCell = wrapped[i];
      // #region agent log
      _dbg(
        runId: 'pre-fix',
        hypothesisId: 'H6',
        location: 'print_service.dart:_billEmitItemTableRow:row-cells',
        message: 'Resolved row cells for fixed-width receipt row',
        data: {
          'rowIndex': i,
          'rowLeft': productCell,
          'qCell': qtyCell,
          'uCell': i == 0 ? u : ' ',
          'tCell': i == 0 ? t : ' ',
        },
      );
      // #endregion
      final product = productCell.isEmpty ? ' ' : productCell;
      final productCol = product.length >= 20 ? product.substring(0, 20) : product.padRight(20);
      final qtyCol = qtyCell.padRight(4);
      final unitCell = (i == 0 ? u : '').padLeft(8);
      final totalCell = (i == 0 ? t : '').padLeft(10);
      bytes.addAll(generator.text('$qtyCol$productCol$unitCell$totalCell'));
    }
  }

  void _billEmitAmountRow(
    Generator generator,
    List<int> bytes, {
    required String label,
    required String amount,
    bool bold = false,
  }) {
    final left = _sanitize(label.trim());
    final right = _sanitize(amount.trim());
    final leftCell = left.length >= 28 ? left.substring(0, 28) : left.padRight(28);
    final rightCell = right.padLeft(14);
    bytes.addAll(
      generator.text(
        '$leftCell$rightCell',
        styles: PosStyles(align: PosAlign.left, bold: bold),
      ),
    );
  }

  void _kotEmitPrintLineBlock(Generator generator, List<int> bytes, _PrintLine line, {required bool bold}) {
    var baseItem = _kotStripTaxVerbiage(line.itemName.trim());
    if (line.variantName != null && line.variantName!.trim().isNotEmpty) {
      baseItem += ' (${_kotStripTaxVerbiage(line.variantName!.trim())})';
    }
    final qtyMain = line.quantity.toString();
    _kotEmitItemQty(generator, bytes, baseItem, qtyStr: qtyMain, bold: bold);

    final tops = line.kotToppings;
    if (tops != null) {
      for (final t in tops) {
        final nm = _kotStripTaxVerbiage(t.$1.trim());
        if (nm.isEmpty) continue;
        final label = '  (+${_sanitize(nm)})';
        _kotEmitItemQty(generator, bytes, label, qtyStr: _kotFmtQty(t.$2));
      }
    } else if (line.toppingInfo != null && line.toppingInfo!.trim().isNotEmpty) {
      bytes.addAll(generator.text('  ${_sanitize(_kotPlainToppingInfo(line.toppingInfo!))}'));
    }

    final lineNoteRaw = _lineNoteFromCartNotes(line.notes);
    final lineNote = lineNoteRaw != null && lineNoteRaw.isNotEmpty ? _kotStripTaxVerbiage(lineNoteRaw) : null;
    if (lineNote != null && lineNote.isNotEmpty) {
      for (final w in _wrapReceiptLine('  Note: ${_sanitize(lineNote)}', 34)) {
        bytes.addAll(generator.text(w));
      }
    }
  }

  void _kotEmitItemQty(
    Generator generator,
    List<int> bytes,
    String rawLeft, {
    required String qtyStr,
    bool bold = false,
  }) {
    final wrapped = _wrapReceiptLine(_sanitize(rawLeft.trim()), 34);
    for (var i = 0; i < wrapped.length; i++) {
      final rowLeft = wrapped[i];
      final qCell = i == 0 ? qtyStr : '';
      bytes.addAll(generator.row([
        PosColumn(
          text: rowLeft.isEmpty ? ' ' : rowLeft,
          width: 8,
          styles: PosStyles(bold: bold),
        ),
        PosColumn(
          text: _sanitize(qCell),
          width: 4,
          styles: PosStyles(bold: bold, align: PosAlign.right),
        ),
      ]));
    }
  }

  Future<List<int>> _generateKOTTicket({
    required List<_PrintLine> items,
    required String branchName,
    required String kitchenName,
    required String referenceNumber,
    required String invoiceNumber,
    required DateTime orderedAt,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    const leftBold = PosStyles(bold: true);
    final safeBranch = branchName.trim();
    if (safeBranch.isNotEmpty) {
      bytes += generator.text(safeBranch, styles: leftBold);
    }
    bytes += generator.text(
      'Kitchen: ${_sanitize(kitchenName)}',
      styles: leftBold,
    );
    bytes += _kotThermalRefInvoiceHeader(
      generator,
      referenceNumber: referenceNumber,
      invoiceNumber: invoiceNumber,
    );
    bytes += generator.feed(1);

    bytes += generator.row([
      PosColumn(
        text: 'item',
        width: 8,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: 'qty',
        width: 4,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);
    bytes += generator.hr(ch: '-');

    for (final line in items) {
      _kotEmitPrintLineBlock(generator, bytes, line, bold: true);
    }

    bytes += generator.hr(ch: '-');
    bytes += generator.feed(1);
    bytes += generator.text(
      'ordered date: ${RuntimeAppSettings.formatDateTime(orderedAt)}',
      styles: const PosStyles(align: PosAlign.left),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  Future<List<int>> _generateKOTUpdateTicket({
    required List<(KotKitchenUpdateRow, _PrintLine)> pairs,
    required String branchName,
    required String kitchenName,
    required String referenceNumber,
    required String invoiceNumber,
    required String orderTypeLabel,
    required DateTime orderedAt,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    const branchStyle = PosStyles(bold: true);
    final safeBranch = branchName.trim();
    if (safeBranch.isNotEmpty) {
      bytes += generator.text(safeBranch, styles: branchStyle);
    }
    bytes += generator.text(
      '--- update order ---',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Kitchen: ${_sanitize(kitchenName)}',
      styles: branchStyle,
    );
    if (orderTypeLabel.isNotEmpty) {
      bytes += generator.text(orderTypeLabel);
    }
    bytes += _kotThermalRefInvoiceHeader(
      generator,
      referenceNumber: referenceNumber,
      invoiceNumber: invoiceNumber,
      referenceBold: false,
    );
    bytes += generator.feed(1);

    bytes += generator.row([
      PosColumn(
        text: 'ITEM',
        width: 8,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: 'QTY',
        width: 4,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);
    bytes += generator.hr(ch: '-');

    for (final p in pairs) {
      final meta = p.$1;
      final pl = p.$2;
      _kotEmitPrintLineBlock(generator, bytes, pl, bold: meta.isCancelled);
      final tag = meta.isCancelled ? '- CANCELLED' : '- UPDATED';
      bytes += generator.text(tag, styles: const PosStyles(bold: true));
      bytes += generator.feed(1);
    }

    bytes += generator.hr(ch: '-');
    bytes += generator.feed(1);
    bytes += generator.text(
      'ordered date: ${RuntimeAppSettings.formatDateTime(orderedAt)}',
      styles: const PosStyles(align: PosAlign.left),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  Future<List<int>> _generateFinalBillTicket({
    required Order order,
    required List<_PrintLine> lines,
    bool settledBill = false,
    bool updatedOrder = false,
    bool asTaxInvoice = true,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    const center = PosStyles(align: PosAlign.center);
    const centerBold = PosStyles(align: PosAlign.center, bold: true);
    const centerTitle = PosStyles(align: PosAlign.center, bold: true);
    const leftInvoice = PosStyles(align: PosAlign.left);

    final branch = await _db.branchesDao.getBranchById(order.branchId);
    final logo = await _tryLoadBranchLogo(branch);

    if (logo != null) {
      try {
        bytes += generator.image(logo, align: PosAlign.center);
        bytes += generator.feed(1);
      } catch (e) {
        if (kDebugMode) debugPrint('PrintService: logo print skipped: $e');
      }
    }

    final branchNameLc = branch?.branchName.trim().toLowerCase() ?? '';

    if (branch != null && branch.branchName.trim().isNotEmpty) {
      bytes += generator.text(
        _sanitize(branch.branchName.trim()),
        styles: center,
      );
    }

    if (branch != null && branch.location.trim().isNotEmpty) {
      final locLines = _dedupeWrappedLines(
        _wrapReceiptLine(_sanitize(branch.location.trim()), 42),
      );
      for (final locLine in locLines) {
        if (branchNameLc.isNotEmpty && locLine.trim().toLowerCase() == branchNameLc) continue;
        bytes += generator.text(locLine, styles: center);
      }
    }
    if (branch != null) {
      final branchContact = branch.contactNo.trim();
      if (branchContact.isNotEmpty) {
        bytes += generator.text(
          'Contact: ${_sanitize(branchContact)}',
          styles: center,
        );
      }
    }
    if (branch != null) {
      final trn = (branch.trnNumber ?? '').toString().trim();
      if (trn.isNotEmpty) {
        bytes += generator.text(
          ' ${_sanitize(trn)}',
          styles: center,
        );
      }
    }

    bytes += generator.feed(1);

    // Keep a single concise title — do not reuse [invoiceHeader] as large duplicated address text.
    final String docTitle;
    if (updatedOrder) {
      docTitle = 'UPDATED ORDER';
    } else if (settledBill) {
      docTitle = asTaxInvoice ? 'TAX INVOICE' : 'RECEIPT';
    } else {
      docTitle = asTaxInvoice ? 'TAX INVOICE' : 'RECEIPT';
    }
    bytes += generator.text(docTitle, styles: centerTitle);
    bytes += generator.feed(1);

    bytes += generator.text('Invoice No. ${_sanitize(order.invoiceNumber)}', styles: leftInvoice);
    bytes += generator.text(
      'Date: ${RuntimeAppSettings.formatDateTime(order.createdAt)}',
      styles: leftInvoice,
    );
    final customer = (order.customerName ?? '').trim();
    bytes += generator.text(
      'Customer: ${_sanitize(customer.isNotEmpty ? customer : 'Walk-In Customer')}',
      styles: leftInvoice,
    );
    final contact = (order.customerPhone ?? '').trim();
    bytes += generator.text(
      'Contact: ${_sanitize(contact.isNotEmpty ? contact : '-')}',
      styles: leftInvoice,
    );

    final totalPayable = order.finalAmount > 0 ? order.finalAmount : order.totalAmount;
    final paidSum = order.cashAmount + order.cardAmount + order.creditAmount + order.onlineAmount;
    if (_receiptShowsPaid(order, totalPayable, paidSum)) {
      bytes += generator.feed(1);
      bytes += generator.text('PAID', styles: leftInvoice);
    }

    final otLabel = _orderTypeLabel(order.orderType);
    if (otLabel.isNotEmpty) {
      bytes += generator.text('Order type: $otLabel', styles: centerBold);
    }

    bytes += generator.feed(1);
    bytes += generator.text('Qty '.padRight(4) + 'Product'.padRight(20) + 'Price'.padLeft(8) + 'Subtotal'.padLeft(10));
    bytes += generator.hr(ch: '-');

    // #region agent log
    await _dbg(
      runId: 'pre-fix',
      hypothesisId: 'H7',
      location: 'print_service.dart:_generateFinalBillTicket:before-items-loop',
      message: 'Receipt layout about to render item table loop',
      data: {
        'orderId': order.id,
        'lineCount': lines.length,
      },
    );
    // #endregion
    for (final line in lines) {
      String name = line.itemName;
      if (line.variantName != null) name += ' (${line.variantName})';
      if (line.toppingInfo != null) name += ' + ${line.toppingInfo}';
      _billEmitItemTableRow(
        generator,
        bytes,
        _sanitize(name),
        line.quantity,
        _fmtMoney(line.unitPrice),
        _fmtMoney(line.total),
      );
    }

    bytes += generator.hr(ch: '-');

    final vatParts = _vatBreakdown(totalPayable, branch);
    final vatMode = branch?.vat.trim().toLowerCase();
    final vatPctDyn = branch?.vatPercent;
    final vatPct = vatPctDyn is num ? vatPctDyn.toDouble() : double.tryParse('$vatPctDyn') ?? 0.0;
    final hasVat = vatMode != null && vatMode != 'no_vat' && vatPct > 0 && vatParts.vatAmount > 0.0001;

    if (order.discountAmount > 0) {
      final offerLine = _offerLineForReceipt(order);
      final discountLine = _discountLineForReceipt(order);
      final manualAmount = (discountLine.amount - (offerLine?.amount ?? 0)).clamp(0.0, order.totalAmount).toDouble();
      _billEmitAmountRow(
        generator,
        bytes,
        label: 'Subtotal:',
        amount: _fmtMoney(order.totalAmount),
      );
      if (offerLine != null) {
        _billEmitAmountRow(
          generator,
          bytes,
          label: offerLine.label,
          amount: '-${_fmtMoney(offerLine.amount)}',
        );
      }
      if (manualAmount > 0.009) {
        _billEmitAmountRow(
          generator,
          bytes,
          label: discountLine.label,
          amount: '-${_fmtMoney(manualAmount)}',
        );
      }
    }

    if (hasVat) {
      _billEmitAmountRow(
        generator,
        bytes,
        label: 'Total Before VAT:',
        amount: _fmtMoney(vatParts.netBeforeVat),
      );
      _billEmitAmountRow(
        generator,
        bytes,
        label: 'VAT Amount:',
        amount: _fmtMoney(vatParts.vatAmount),
      );
      _billEmitAmountRow(
        generator,
        bytes,
        label: 'Total With VAT:',
        amount: _fmtMoney(totalPayable),
      );
      _billEmitAmountRow(
        generator,
        bytes,
        label: 'Grand Total:',
        amount: _fmtMoney(totalPayable),
        bold: true,
      );
    } else {
      _billEmitAmountRow(
        generator,
        bytes,
        label: 'Total:',
        amount: _fmtMoney(totalPayable),
        bold: true,
      );
    }

    _billEmitAmountRow(
      generator,
      bytes,
      label: 'Total paid',
      amount: _fmtMoney(paidSum),
      bold: true,
    );

    if (order.cashAmount > 0.004) {
      _billEmitAmountRow(
        generator,
        bytes,
        label: 'Cash',
        amount: _fmtMoney(order.cashAmount),
      );
    }
    if (order.cardAmount > 0.004) {
      _billEmitAmountRow(
        generator,
        bytes,
        label: 'Card',
        amount: _fmtMoney(order.cardAmount),
      );
    }
    if (order.onlineAmount > 0.004) {
      _billEmitAmountRow(
        generator,
        bytes,
        label: 'Online',
        amount: _fmtMoney(order.onlineAmount),
      );
    }
    if (order.creditAmount > 0.004) {
      _billEmitAmountRow(
        generator,
        bytes,
        label: 'Credit',
        amount: _fmtMoney(order.creditAmount),
      );
    }
    if (hasVat) {
      bytes += generator.text(
        '${vatPct.toStringAsFixed(2)}% (inclusive)',
        styles: center,
      );
    }

    bytes += generator.feed(1);

    final brand = branch?.branchName.trim() ?? '';
    bytes += generator.text('Sip, smile, Repeat!', styles: center);
    if (brand.isNotEmpty) {
      bytes += generator.text(
        'Thank you for choosing ${_sanitize(brand)}!',
        styles: center,
      );
    } else {
      bytes += generator.text('Thank you!', styles: center);
    }

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  Future<List<int>> _generateDayClosingTicket({
    required String title,
    required List<({String label, double amount})> rows,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text(
      _sanitize(title.toUpperCase()),
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    );
    bytes += generator.text(
      RuntimeAppSettings.formatDateTime(DateTime.now()),
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.feed(1);
    bytes += generator.hr();

    for (final row in rows) {
      bytes += generator.row([
        PosColumn(text: _sanitize(row.label.toUpperCase()), width: 8),
        PosColumn(text: '$_currency${row.amount.toStringAsFixed(2)}', width: 4),
      ]);
    }

    bytes += generator.hr();
    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  Future<void> _sendToPrinter({
    required String jobKind,
    required String address,
    required int port,
    required List<int> bytes,
    String printerLabel = 'Printer',
    required String connectionType,
    String? vendorId,
    String? productId,
  }) async {
    final connType = connectionType;
    _logPrinterPayloadHeading(
      jobKind: jobKind,
      printerLabel: printerLabel,
      connectionType: connType,
      address: address,
      port: port,
      vendorId: vendorId,
      productId: productId,
      bytes: bytes,
    );
    final plugin = FlutterThermalPrinter.instance;

    if (connType == 'network') {
      // Network: address=IP, port=port
      final service = FlutterThermalPrinterNetwork(
        address,
        port: port,
        timeout: _connectionTimeout,
      );
      final connectResult = await service.connect();
      if (connectResult != NetworkPrintResult.success) {
        final err = Exception('$printerLabel not found. Ensure the printer is on and connected (IP: $address:$port). connectResult=$connectResult');
        debugPrint('PrintService: Network printer error [$printerLabel]: $err');
        throw err;
      }
      final printResult = await service.printTicket(bytes);
      await service.disconnect();
      if (printResult != NetworkPrintResult.success) {
        final err = Exception('$printerLabel failed to print. Check connection (IP: $address:$port). printResult=$printResult');
        debugPrint('PrintService: Network printer error [$printerLabel]: $err');
        throw err;
      }
    } else {
      // USB or BLE: build Printer from stored address/vendorId/productId.
      // Plugin can crash on null in printData for USB (e.g. printer_manager.dart:234 uses !);
      // for USB only, pass non-null strings so the plugin never sees null.
      // On Windows the plugin reports vendorId/address as the printer name (e.g. "BP-T3") and productId as "N/A".
      // Windows USB print uses printer.name! for OpenPrinter() (Win32); must set name to exact Windows printer name.
      final isUsb = connType == 'usb';
      final safeVid = isUsb ? _normalizeUsbId(vendorId) : vendorId;
      final safePid = isUsb ? _normalizeUsbId(productId, emptyDefault: '0') : productId;
      final effectiveAddress = isUsb && address.isEmpty && (safeVid?.isNotEmpty ?? false) ? (safeVid ?? '') : address;
      final windowsPrinterName = effectiveAddress.isNotEmpty ? effectiveAddress : (safeVid?.isNotEmpty ?? false ? safeVid! : null);
      final printer = Printer(
        address: (effectiveAddress.isEmpty) ? null : effectiveAddress,
        name: isUsb ? (windowsPrinterName ?? safeVid) : null,
        connectionType: isUsb ? ConnectionType.USB : ConnectionType.BLE,
        vendorId: isUsb ? safeVid : vendorId,
        productId: isUsb ? safePid : productId,
      );
      try {
        final connected = await plugin.connect(printer);
        if (!connected) {
          throw Exception('$printerLabel not found. Ensure the printer is on and paired.');
        }
        try {
          await plugin.printData(printer, bytes, longData: true);
        } finally {
          await plugin.disconnect(printer);
        }
      } catch (e, st) {
        debugPrint('PrintService: Printer error [$printerLabel]: $e');
        debugPrint('PrintService: stack trace:\n$st');
        final msg = e.toString();
        if (msg.contains('Unreachable') || msg.contains('UniversalBle') || (connType == 'ble' && msg.contains('Ble'))) {
          throw Exception(
            '$printerLabel: Bluetooth printer unreachable. '
            'Turn the printer on, stay in range, and try again.',
          );
        }
        rethrow;
      }
    }
  }

  /// Normalize USB vendor/product ID: never return null.
  /// Treat null, empty, "N/A" as empty string (or [emptyDefault] for productId).
  /// Plugin can crash on null in printData; some devices report productId "N/A" so use '0' as fallback.
  static String _normalizeUsbId(String? v, {String emptyDefault = ''}) {
    if (v == null || v.isEmpty) return emptyDefault;
    final t = v.trim().toLowerCase();
    if (t == 'n/a' || t == 'na') return emptyDefault;
    return v.trim();
  }

  /// Decode stored address: "ble|ADDR", "usb|vid|pid", or plain IP for network
  /// Returns (address, vendorId, productId, connectionType)
  (String address, String? vendorId, String? productId, String connectionType) _decodeAddress(String raw) {
    if (raw.startsWith('ble|')) return (raw.substring(4), null, null, 'ble');
    if (raw.startsWith('usb|')) {
      final parts = raw.substring(4).split('|');
      final vid = parts.isNotEmpty ? parts[0] : null;
      final pid = parts.length > 1 ? parts[1] : null;
      // For USB, address is unused; vendorId/productId identify the device
      return ('', vid, pid, 'usb');
    }
    return (raw, null, null, 'network');
  }

  /// Save printer config for a kitchen. kitchenId=0 for bill printer.
  /// For kitchenId > 0, saves to Kitchens table (IP/port on kitchen).
  Future<void> setKitchenPrinter({
    required int kitchenId,
    required String ip,
    int port = _defaultPort,
  }) async {
    if (kitchenId == 0) {
      await _db.itemDao.upsertKitchenPrinter(
        KitchenPrintersCompanion.insert(printerIp: ip, printerPort: Value(port)).copyWith(kitchenId: const Value(0)),
      );
    } else {
      await _db.itemDao.updateKitchenPrinter(
        kitchenId: kitchenId,
        printerIp: ip,
        printerPort: port,
      );
    }
  }
}

class _PrintLine {
  final String itemName;
  final String? variantName;
  final String? toppingInfo;

  /// Structured toppings for KOT (one indented row each); bill still uses [toppingInfo].
  final List<(String name, num qty)>? kotToppings;
  final int quantity;
  final double unitPrice;
  final double total;
  final String? notes;
  final int? kitchenId;
  final String? kitchenName;

  _PrintLine({
    required this.itemName,
    this.variantName,
    this.toppingInfo,
    this.kotToppings,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.notes,
    this.kitchenId,
    this.kitchenName,
  });
}
