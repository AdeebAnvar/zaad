import 'dart:typed_data';

import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/branch_model.dart';

enum ReceiptPreviewKind { receipt, rawTicket }

class ReceiptPreviewData {
  ReceiptPreviewData.receipt({
    required this.previewTitle,
    required this.previewSubtitle,
    required this.order,
    required this.lines,
    required this.branch,
    this.logoPngBytes,
    required this.settledBill,
    required this.updatedOrder,
    required this.asTaxInvoice,
  })  : kind = ReceiptPreviewKind.receipt,
        rawLines = const [];

  ReceiptPreviewData.rawTicket({
    required this.previewTitle,
    required this.previewSubtitle,
    required this.rawLines,
  })  : kind = ReceiptPreviewKind.rawTicket,
        order = null,
        lines = const [],
        branch = null,
        logoPngBytes = null,
        settledBill = false,
        updatedOrder = false,
        asTaxInvoice = false;

  final ReceiptPreviewKind kind;
  final String previewTitle;
  final String previewSubtitle;
  final Order? order;
  final List<ReceiptPreviewLine> lines;
  final BranchModel? branch;
  final Uint8List? logoPngBytes;
  final bool settledBill;
  final bool updatedOrder;
  final bool asTaxInvoice;
  final List<String> rawLines;
}

class ReceiptPreviewLine {
  ReceiptPreviewLine({
    required this.itemName,
    this.variantName,
    this.toppingInfo,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final String itemName;
  final String? variantName;
  final String? toppingInfo;
  final int quantity;
  final double unitPrice;
  final double total;
}
