import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/network/network_print_result.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:intl/intl.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/item_repository.dart';

/// Handles KOT (per-kitchen) and final bill printing.
class PrintService {
  PrintService(this._db, this._itemRepo);

  final AppDatabase _db;
  final ItemRepository _itemRepo;

  static const int _defaultPort = 9100;
  static const Duration _connectionTimeout = Duration(seconds: 15);

  /// Use ASCII "Rs" on receipts; thermal printers often don't support Unicode ₹.
  static const String _currency = 'Rs ';

  /// Strip ₹ from any string (item names, notes, etc.) so printer receives ASCII-only.
  static String _sanitize(String s) => s.replaceAll('₹', 'Rs');

  /// Groups cart items by kitchen and prints KOT to each kitchen's printer.
  /// [referenceNumber] e.g. table number or order ref.
  /// Returns list of printer labels that failed (working printers still print).
  Future<List<String>> printKOTPerKitchen({
    required List<CartItem> cartItems,
    required String referenceNumber,
  }) async {
    final failed = <String>[];
    if (cartItems.isEmpty) return failed;

    final lines = await _buildPrintLines(cartItems);
    final byKitchen = <int?, List<_PrintLine>>{};
    for (final line in lines) {
      byKitchen.putIfAbsent(line.kitchenId, () => []).add(line);
    }

    for (final entry in byKitchen.entries) {
      final kitchenId = entry.key ?? 0;
      String? printerIp;
      int printerPort = _defaultPort;

      if (kitchenId == 0) {
        final billPrinter = await _db.itemDao.getBillPrinter();
        if (billPrinter != null && billPrinter.printerIp.isNotEmpty) {
          printerIp = billPrinter.printerIp;
          printerPort = billPrinter.printerPort;
        }
      } else {
        final kitchen = await _db.itemDao.getKitchenById(kitchenId);
        if (kitchen != null &&
            kitchen.printerIp != null &&
            kitchen.printerIp!.isNotEmpty) {
          printerIp = kitchen.printerIp;
          printerPort = kitchen.printerPort;
        } else {
          final kitchenPrinter = await _db.itemDao.getPrinterByKitchenId(kitchenId);
          if (kitchenPrinter != null && kitchenPrinter.printerIp.isNotEmpty) {
            printerIp = kitchenPrinter.printerIp;
            printerPort = kitchenPrinter.printerPort;
          }
        }
      }

      if (printerIp == null || printerIp.isEmpty) {
        if (kDebugMode) {
          debugPrint('PrintService: No printer configured for kitchen $kitchenId');
        }
        continue;
      }

      final kitchen = kitchenId > 0 ? await _db.itemDao.getKitchenById(kitchenId) : null;
      final kitchenName = kitchen?.name ?? 'General';
      final printerLabel = 'Kitchen "$kitchenName" printer';

      try {
        final bytes = await _generateKOTTicket(
          items: entry.value,
          referenceNumber: referenceNumber,
          kitchenName: kitchenName,
        );
        final (address, vendorId, productId, connType) = _decodeAddress(printerIp);
        await _sendToPrinter(
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
    return failed;
  }

  /// Prints final bill (customer receipt) with all items.
  /// Uses bill printer (kitchen_id=0).
  /// Returns list of printer labels that failed (working printers still print).
  Future<List<String>> printFinalBill({
    required Order order,
    required List<CartItem> cartItems,
    /// When true (e.g. customer bill from order log), receipt shows a settled-bill header.
    bool settledBill = false,
    /// When true, print header indicates edited bill.
    bool updatedOrder = false,
  }) async {
    final failed = <String>[];
    final lines = await _buildPrintLines(cartItems);
    final billPrinter = await _db.itemDao.getBillPrinter();
    if (billPrinter == null || billPrinter.printerIp.isEmpty) {
      if (kDebugMode) debugPrint('PrintService: No bill printer configured');
      return failed;
    }

    const printerLabel = 'Bill printer';
    try {
      final bytes = await _generateFinalBillTicket(
        order: order,
        lines: lines,
        settledBill: settledBill,
        updatedOrder: updatedOrder,
      );
      final (address, vendorId, productId, connType) = _decodeAddress(billPrinter.printerIp);
      await _sendToPrinter(
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

  Future<List<_PrintLine>> _buildPrintLines(List<CartItem> cartItems) async {
    final lines = <_PrintLine>[];
    for (final ci in cartItems) {
      final item = await _itemRepo.fetchItemByIdFromLocal(ci.itemId);
      ItemVariant? variant;
      if (ci.itemVariantId != null) {
        variant = await _itemRepo.fetchVariantById(ci.itemVariantId!);
      }
      ItemTopping? topping;
      if (ci.itemToppingId != null) {
        topping = await _itemRepo.fetchToppingById(ci.itemToppingId!);
      }

      String? toppingInfo;
      final toppingsData = _decodeToppingsJson(ci.notes);
      if (toppingsData != null && toppingsData.isNotEmpty) {
        toppingInfo = toppingsData
            .map((t) => '${t['name'] ?? ''} x${t['qty'] ?? 1}')
            .join(', ');
      } else if (topping != null) {
        toppingInfo = '${topping.name} (+$_currency${topping.price.toStringAsFixed(0)})';
      }

      lines.add(_PrintLine(
        itemName: _sanitize(item?.name ?? 'Unknown'),
        variantName: variant?.name != null ? _sanitize(variant!.name) : null,
        toppingInfo: toppingInfo?.isNotEmpty == true ? _sanitize(toppingInfo!) : null,
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
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<int>> _generateKOTTicket({
    required List<_PrintLine> items,
    required String referenceNumber,
    required String kitchenName,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text(
      'KITCHEN ORDER',
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    );
    bytes += generator.feed(1);
    bytes += generator.text(
      _sanitize(kitchenName).toUpperCase(),
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      _sanitize('Ref: $referenceNumber'),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);
    bytes += generator.hr();

    for (final line in items) {
      String name = line.itemName;
      if (line.variantName != null) name += ' (${line.variantName})';
      if (line.toppingInfo != null) name += ' + ${line.toppingInfo}';

      bytes += generator.row([
        PosColumn(text: _sanitize('${line.quantity}x $name'), width: 8),
        PosColumn(text: '$_currency${line.total.toStringAsFixed(0)}', width: 4),
      ]);
      // Show free-text note only if notes is not JSON (toppings stored as JSON)
      if (line.notes != null && line.notes!.isNotEmpty) {
        try {
          jsonDecode(line.notes!);
          // It's JSON (toppings), already shown in toppingInfo
        } catch (_) {
          bytes += generator.text('  Note: ${_sanitize(line.notes!)}');
        }
      }
    }

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  Future<List<int>> _generateFinalBillTicket({
    required Order order,
    required List<_PrintLine> lines,
    bool settledBill = false,
    bool updatedOrder = false,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    final caption = updatedOrder ? 'UPDATED ORDER' : (settledBill ? 'SETTLED BILL' : 'RECEIPT');
    // #region agent log
    _dbgLog('final_bill_caption', {
      'invoiceNumber': order.invoiceNumber,
      'updatedOrder': updatedOrder,
      'settledBill': settledBill,
      'caption': caption,
    }, hypothesisId: 'H1');
    // #endregion
    bytes += generator.text(
      caption,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    );
    bytes += generator.text(
      _sanitize(order.invoiceNumber),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      _sanitize(order.referenceNumber ?? ''),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      DateFormat('dd-MM-yyyy HH:mm').format(order.createdAt),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);
    bytes += generator.hr();

    for (final line in lines) {
      String name = line.itemName;
      if (line.variantName != null) name += ' (${line.variantName})';
      if (line.toppingInfo != null) name += ' + ${line.toppingInfo}';

      bytes += generator.row([
        PosColumn(text: _sanitize('${line.quantity}x $name'), width: 8),
        PosColumn(text: '$_currency${line.total.toStringAsFixed(0)}', width: 4),
      ]);
    }

    bytes += generator.hr();
    if (order.discountAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Subtotal', width: 8),
        PosColumn(text: '$_currency${order.totalAmount.toStringAsFixed(2)}', width: 4),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Discount', width: 8),
        PosColumn(text: '-$_currency${order.discountAmount.toStringAsFixed(2)}', width: 4),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(
        text: '$_currency${(order.finalAmount > 0 ? order.finalAmount : order.totalAmount).toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(bold: true),
      ),
    ]);

    bytes += generator.feed(2);
    bytes += generator.text('Thank you!', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  // #region agent log
  void _dbgLog(String message, Map<String, Object?> data, {String hypothesisId = 'H1'}) {
    try {
      final payload = {
        'sessionId': 'bead4f',
        'runId': 'updated-order-caption',
        'hypothesisId': hypothesisId,
        'location': 'print_service.dart',
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      File('debug-bead4f.log').writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }
  // #endregion

  Future<void> _sendToPrinter({
    required String address,
    required int port,
    required List<int> bytes,
    String printerLabel = 'Printer',
    required String connectionType,
    String? vendorId,
    String? productId,
  }) async {
    final connType = connectionType;
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
        if (msg.contains('Unreachable') ||
            msg.contains('UniversalBle') ||
            (connType == 'ble' && msg.contains('Ble'))) {
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
        KitchenPrintersCompanion.insert(printerIp: ip, printerPort: Value(port))
            .copyWith(kitchenId: const Value(0)),
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
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.notes,
    this.kitchenId,
    this.kitchenName,
  });
}
