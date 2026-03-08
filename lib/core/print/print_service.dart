import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:intl/intl.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/item_repository.dart';

/// Handles KOT (per-kitchen) and final bill printing.
class PrintService {
  PrintService(this._db, this._itemRepo);

  final AppDatabase _db;
  final ItemRepository _itemRepo;

  static const int _defaultPort = 9100;

  /// Groups cart items by kitchen and prints KOT to each kitchen's printer.
  /// [referenceNumber] e.g. table number or order ref.
  Future<void> printKOTPerKitchen({
    required List<CartItem> cartItems,
    required String referenceNumber,
  }) async {
    if (cartItems.isEmpty) return;

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

      final bytes = await _generateKOTTicket(
        items: entry.value,
        referenceNumber: referenceNumber,
        kitchenName: kitchenName,
      );
      await _sendToPrinter(
        ip: printerIp,
        port: printerPort,
        bytes: bytes,
      );
    }
  }

  /// Prints final bill (customer receipt) with all items.
  /// Uses bill printer (kitchen_id=0).
  Future<void> printFinalBill({
    required Order order,
    required List<CartItem> cartItems,
  }) async {
    final lines = await _buildPrintLines(cartItems);
    final billPrinter = await _db.itemDao.getBillPrinter();
    if (billPrinter == null || billPrinter.printerIp.isEmpty) {
      if (kDebugMode) debugPrint('PrintService: No bill printer configured');
      return;
    }

    final bytes = await _generateFinalBillTicket(
      order: order,
      lines: lines,
    );
    await _sendToPrinter(
      ip: billPrinter.printerIp,
      port: billPrinter.printerPort,
      bytes: bytes,
    );
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
        toppingInfo = '${topping.name} (+₹${topping.price.toStringAsFixed(0)})';
      }

      lines.add(_PrintLine(
        itemName: item?.name ?? 'Unknown',
        variantName: variant?.name,
        toppingInfo: toppingInfo?.isNotEmpty == true ? toppingInfo : null,
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
      kitchenName.toUpperCase(),
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Ref: $referenceNumber',
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
      if (line.toppingInfo != null) name += ' + $line.toppingInfo';

      bytes += generator.row([
        PosColumn(text: '${line.quantity}x $name', width: 8),
        PosColumn(text: '₹${line.total.toStringAsFixed(0)}', width: 4),
      ]);
      // Show free-text note only if notes is not JSON (toppings stored as JSON)
      if (line.notes != null && line.notes!.isNotEmpty) {
        try {
          jsonDecode(line.notes!);
          // It's JSON (toppings), already shown in toppingInfo
        } catch (_) {
          bytes += generator.text('  Note: ${line.notes}');
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
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text(
      'RECEIPT',
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    );
    bytes += generator.text(
      order.invoiceNumber,
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      order.referenceNumber ?? '',
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
        PosColumn(text: '${line.quantity}x $name', width: 8),
        PosColumn(text: '₹${line.total.toStringAsFixed(0)}', width: 4),
      ]);
    }

    bytes += generator.hr();
    if (order.discountAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Subtotal', width: 8),
        PosColumn(text: '₹${order.totalAmount.toStringAsFixed(2)}', width: 4),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Discount', width: 8),
        PosColumn(text: '-₹${order.discountAmount.toStringAsFixed(2)}', width: 4),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(
        text: '₹${(order.finalAmount > 0 ? order.finalAmount : order.totalAmount).toStringAsFixed(2)}',
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

  Future<void> _sendToPrinter({
    required String ip,
    required int port,
    required List<int> bytes,
  }) async {
    final printer = PrinterNetworkManager(ip, port: port);
    final result = await printer.connect();
    if (result == PosPrintResult.success) {
      await printer.printTicket(bytes);
      printer.disconnect();
    } else {
      throw Exception('Printer connection failed: ${result.msg}');
    }
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
