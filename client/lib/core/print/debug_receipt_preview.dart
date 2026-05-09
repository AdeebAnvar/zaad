import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/core/print/receipt_preview_data.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/branch_model.dart';

OverlayEntry? _activeReceiptPreviewEntry;
const double _previewPaperWidthMm = 100.1;
const double _previewPaperHeightMm = 297.0;

Future<void> _dbg73ad8e({
  required String runId,
  required String hypothesisId,
  required String location,
  required String message,
  required Map<String, Object?> data,
}) async {
  final payload = <String, Object?>{
    'sessionId': '73ad8e',
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  try {
    await File(r'C:\Users\adeeb\OneDrive\Desktop\pos\pos\debug-73ad8e.log').writeAsString(
      '${jsonEncode(payload)}\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (_) {}
}

void scheduleDebugReceiptPreview(ReceiptPreviewData data) {
  // #region agent log
  _dbg73ad8e(
    runId: 'pre-fix',
    hypothesisId: 'H3',
    location: 'debug_receipt_preview.dart:scheduleDebugReceiptPreview',
    message: 'Debug preview scheduling requested',
    data: {
      'kDebugMode': kDebugMode,
      'kind': data.kind.name,
    },
  );
  // #endregion
  if (!kDebugMode) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Delay helps when printing starts from a dialog that pops right after completion.
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      _showDebugReceiptPreview(data);
    });
  });
}

void _showDebugReceiptPreview(ReceiptPreviewData data, {int attempt = 0}) {
  final navigator = AppNavigator.navigatorKey.currentState;
  final overlay = navigator?.overlay;
  final ctx = overlay?.context ?? navigator?.context;
  if (overlay == null || ctx == null || !ctx.mounted) {
    if (attempt >= 4) {
      debugPrint('ReceiptPreview: navigator overlay unavailable after retries');
      return;
    }
    Future<void>.delayed(
      const Duration(milliseconds: 150),
      () => _showDebugReceiptPreview(data, attempt: attempt + 1),
    );
    return;
  }
  final maxHeight = MediaQuery.sizeOf(ctx).height * 0.92;
  debugPrint('ReceiptPreview: inserting overlay preview (attempt=$attempt)');
  try {
    _activeReceiptPreviewEntry?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ReceiptPreviewOverlay(
        data: data,
        maxHeight: maxHeight,
        onClose: () {
          if (entry.mounted) entry.remove();
          if (identical(_activeReceiptPreviewEntry, entry)) {
            _activeReceiptPreviewEntry = null;
          }
        },
      ),
    );
    _activeReceiptPreviewEntry = entry;
    overlay.insert(entry);
  } catch (e, st) {
    debugPrint('ReceiptPreview: failed to insert overlay preview: $e');
    debugPrint('ReceiptPreview: stack trace:\n$st');
  }
}

class _ReceiptPreviewOverlay extends StatelessWidget {
  const _ReceiptPreviewOverlay({
    required this.data,
    required this.maxHeight,
    required this.onClose,
  });

  final ReceiptPreviewData data;
  final double maxHeight;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final widthFromHeight = maxHeight * (_previewPaperWidthMm / _previewPaperHeightMm);
    final previewWidth = widthFromHeight.clamp(220.0, screen.width - 24);
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: previewWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: previewWidth,
                      maxHeight: maxHeight,
                    ),
                    child: _DebugReceiptPreviewSheet(
                      data: data,
                      onClose: onClose,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Layout helpers: keep aligned with [PrintService._generateFinalBillTicket]. ---

String _sanitize(String s) => s.replaceAll('₹', 'Rs');

String _fmtMoney(num v) => v.toStringAsFixed(RuntimeAppSettings.decimalDigits);

String _orderTypeLabel(String? raw) {
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

({double netBeforeVat, double vatAmount}) _vatBreakdown(double totalInclusive, BranchModel? branch) {
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

({String label, double amount}) _discountLineForPreview(Order order) {
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

bool _receiptShowsPaid(Order order, double totalPayable, double paidSum) {
  final st = order.status.trim().toLowerCase();
  if (st == 'cancelled') return false;
  if (st == 'completed') return true;
  if (totalPayable <= 0.009) return false;
  return paidSum + 0.02 >= totalPayable;
}

List<String> _dedupeWrappedLines(List<String> lines) {
  final seen = <String>{};
  final out = <String>[];
  for (final l in lines) {
    final k = l.trim().toLowerCase();
    if (k.isEmpty) continue;
    if (seen.add(k)) out.add(l.trim());
  }
  return out;
}

List<String> _wrapReceiptLine(String text, int maxChars) {
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

String _previewAmountRow({
  required String label,
  required String amount,
}) {
  final left = _sanitize(label.trim());
  final right = _sanitize(amount.trim());
  final leftCell = left.length >= 28 ? left.substring(0, 28) : left.padRight(28);
  final rightCell = right.padLeft(14);
  return '$leftCell$rightCell';
}

class _DebugReceiptPreviewSheet extends StatelessWidget {
  const _DebugReceiptPreviewSheet({
    required this.data,
    required this.onClose,
  });

  final ReceiptPreviewData data;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.previewTitle,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            Text(
              data.previewSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Material(
                color: Colors.white,
                elevation: 1,
                borderRadius: BorderRadius.circular(8),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: data.kind == ReceiptPreviewKind.receipt ? _ReceiptPaper(data: data) : _RawTicketPaper(data: data),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptPaper extends StatelessWidget {
  const _ReceiptPaper({required this.data});

  final ReceiptPreviewData data;

  @override
  Widget build(BuildContext context) {
    // #region agent log
    _dbg73ad8e(
      runId: 'pre-fix',
      hypothesisId: 'H1',
      location: 'debug_receipt_preview.dart:_ReceiptPaper:build',
      message: 'Rendering preview ticket template',
      data: {
        'kind': data.kind.name,
        'lineCount': data.lines.length,
        'asTaxInvoice': data.asTaxInvoice,
        'updatedOrder': data.updatedOrder,
        'settledBill': data.settledBill,
      },
    );
    // #endregion
    final order = data.order!;
    final branch = data.branch;
    final lines = data.lines;

    final branchNameLc = branch?.branchName.trim().toLowerCase() ?? '';

    final String docTitle;
    if (data.updatedOrder) {
      docTitle = 'UPDATED ORDER';
    } else if (data.settledBill) {
      docTitle = data.asTaxInvoice ? 'TAX INVOICE' : 'RECEIPT';
    } else {
      docTitle = data.asTaxInvoice ? 'TAX INVOICE' : 'RECEIPT';
    }

    final totalPayable = order.finalAmount > 0 ? order.finalAmount : order.totalAmount;
    final paidSum = order.cashAmount + order.cardAmount + order.creditAmount + order.onlineAmount;
    final vatParts = _vatBreakdown(totalPayable, branch);
    final vatMode = branch?.vat.trim().toLowerCase();
    final vatPctDyn = branch?.vatPercent;
    final vatPct = vatPctDyn is num ? vatPctDyn.toDouble() : double.tryParse('$vatPctDyn') ?? 0.0;
    final hasVat = vatMode != null && vatMode != 'no_vat' && vatPct > 0 && vatParts.vatAmount > 0.0001;

    final otLabel = _orderTypeLabel(order.orderType);

    const mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: 11.5,
      height: 1.25,
      color: Colors.black87,
    );
    const monoBold = TextStyle(
      fontFamily: 'monospace',
      fontSize: 11.5,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    );
    const titleStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 14,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    );
    final itemHeaderPreview = 'Qty '.padRight(4) + 'Product'.padRight(20) + 'Price'.padLeft(8) + 'Subtotal'.padLeft(10);
    const invoiceLabelPreview = 'Invoice No.';
    const trnLabelPreview = 'RAW_TRN';

    final children = <Widget>[];

    final logo = data.logoPngBytes;
    if (logo != null) {
      children.add(
        Center(
          child: Image.memory(
            logo,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
      children.add(const SizedBox(height: 8));
    }

    if (branch != null && branch.branchName.trim().isNotEmpty) {
      children.add(
        Text(
          _sanitize(branch.branchName.trim()),
          style: mono,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (branch != null && branch.location.trim().isNotEmpty) {
      final locLines = _dedupeWrappedLines(
        _wrapReceiptLine(_sanitize(branch.location.trim()), 42),
      );
      for (final locLine in locLines) {
        if (branchNameLc.isNotEmpty && locLine.trim().toLowerCase() == branchNameLc) continue;
        children.add(
          Text(
            locLine,
            style: mono,
            textAlign: TextAlign.center,
          ),
        );
      }
    }

    if (branch != null) {
      final branchContact = branch.contactNo.trim();
      if (branchContact.isNotEmpty) {
        children.add(
          Text(
            'Contact: ${_sanitize(branchContact)}',
            style: mono,
            textAlign: TextAlign.center,
          ),
        );
      }
    }

    if (branch != null) {
      final trn = (branch.trnNumber ?? '').toString().trim();
      if (trn.isNotEmpty) {
        children.add(
          Text(
            ' ${_sanitize(trn)}',
            style: mono,
            textAlign: TextAlign.center,
          ),
        );
      }
    }

    children.add(const SizedBox(height: 8));
    children.add(Text(docTitle, style: titleStyle, textAlign: TextAlign.center));
    children.add(const SizedBox(height: 8));

    children.add(Text('Invoice No. ${_sanitize(order.invoiceNumber)}', style: mono));
    children.add(Text('Date: ${RuntimeAppSettings.formatDateTime(order.createdAt)}', style: mono));
    final customer = (order.customerName ?? '').trim();
    children.add(Text('Customer: ${_sanitize(customer.isNotEmpty ? customer : 'Walk-In Customer')}', style: mono));
    final contact = (order.customerPhone ?? '').trim();
    children.add(Text('Contact: ${_sanitize(contact.isNotEmpty ? contact : '-')}', style: mono));

    if (_receiptShowsPaid(order, totalPayable, paidSum)) {
      children.add(const SizedBox(height: 8));
      children.add(const Text('PAID', style: mono, textAlign: TextAlign.left));
    }

    if (otLabel.isNotEmpty) {
      children.add(Text('Order type: $otLabel', style: monoBold, textAlign: TextAlign.center));
    }

    children.add(const SizedBox(height: 10));
    children.add(Text(itemHeaderPreview, style: monoBold));
    children.add(Text('-' * 42, style: mono));

    for (final line in lines) {
      var name = line.itemName;
      if (line.variantName != null) name += ' (${line.variantName})';
      if (line.toppingInfo != null) name += ' + ${line.toppingInfo}';
      final wrapped = _wrapReceiptLine(_sanitize(name.trim()), 20);
      final u = _fmtMoney(line.unitPrice);
      final t = _fmtMoney(line.total);
      for (var i = 0; i < wrapped.length; i++) {
        final product = wrapped[i].isEmpty ? ' ' : wrapped[i];
        final productCell = product.length >= 20 ? product.substring(0, 20) : product.padRight(20);
        final qtyCell = (i == 0 ? '${line.quantity}' : '').padRight(4);
        final unitCell = (i == 0 ? u : '').padLeft(8);
        final totalCell = (i == 0 ? t : '').padLeft(10);
        children.add(Text('$qtyCell$productCell$unitCell$totalCell', style: mono));
      }
      final cap = line.receiptDiscountCaption?.trim();
      if (cap != null && cap.isNotEmpty) {
        for (final w in _wrapReceiptLine('    ${_sanitize(cap)}', 42)) {
          children.add(Text(w, style: mono));
        }
      }
    }

    children.add(Text('-' * 42, style: mono));

    final aggregateLineDiscount = lines.fold<double>(0, (a, e) => a + e.lineDiscountAmount);
    if (aggregateLineDiscount > 0.009) {
      children.add(
        Text(
          _previewAmountRow(label: 'Total item discounts:', amount: '-${_fmtMoney(aggregateLineDiscount)}'),
          style: mono,
        ),
      );
    }

    if (order.discountAmount > 0) {
      final discountLine = _discountLineForPreview(order);
      children.add(
        Text(
          _previewAmountRow(label: 'Subtotal:', amount: _fmtMoney(order.totalAmount)),
          style: mono,
        ),
      );
      children.add(
        Text(
          _previewAmountRow(label: discountLine.label, amount: '-${_fmtMoney(discountLine.amount)}'),
          style: mono,
        ),
      );
    }

    if (hasVat) {
      children.add(
        Text(
          _previewAmountRow(label: 'Total Before VAT:', amount: _fmtMoney(vatParts.netBeforeVat)),
          style: mono,
        ),
      );
      children.add(
        Text(
          _previewAmountRow(
              label: 'VAT Amount (${vatPct.toStringAsFixed(2)}% incl.):',
              amount: _fmtMoney(vatParts.vatAmount)),
          style: mono,
        ),
      );
      children.add(
        Text(
          _previewAmountRow(label: 'Total With VAT:', amount: _fmtMoney(totalPayable)),
          style: mono,
        ),
      );
      children.add(
        Text(
          _previewAmountRow(label: 'Grand Total:', amount: _fmtMoney(totalPayable)),
          style: monoBold,
        ),
      );
    } else {
      children.add(
        Text(
          _previewAmountRow(label: 'Total:', amount: _fmtMoney(totalPayable)),
          style: monoBold,
        ),
      );
    }
    children.add(
      Text(
        _previewAmountRow(label: 'Total paid', amount: _fmtMoney(paidSum)),
        style: monoBold,
      ),
    );

    if (order.cashAmount > 0.004) {
      children.add(Text(_previewAmountRow(label: 'Cash', amount: _fmtMoney(order.cashAmount)), style: mono));
    }
    if (order.cardAmount > 0.004) {
      children.add(Text(_previewAmountRow(label: 'Card', amount: _fmtMoney(order.cardAmount)), style: mono));
    }
    if (order.onlineAmount > 0.004) {
      children.add(Text(_previewAmountRow(label: 'Online', amount: _fmtMoney(order.onlineAmount)), style: mono));
    }
    if (order.creditAmount > 0.004) {
      children.add(Text(_previewAmountRow(label: 'Credit', amount: _fmtMoney(order.creditAmount)), style: mono));
    }

    children.add(const SizedBox(height: 8));
    children.add(const Text('Sip, smile, Repeat!', style: mono, textAlign: TextAlign.center));
    final brand = branch?.branchName.trim() ?? '';
    if (brand.isNotEmpty) {
      children.add(
        Text(
          'Thank you for choosing ${_sanitize(brand)}!',
          style: mono,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      children.add(const Text('Thank you!', style: mono, textAlign: TextAlign.center));
    }

    // #region agent log
    _dbg73ad8e(
      runId: 'pre-fix',
      hypothesisId: 'H2',
      location: 'debug_receipt_preview.dart:_ReceiptPaper:layout-signature',
      message: 'Preview layout signature before sync fix',
      data: {
        'invoiceLabel': invoiceLabelPreview,
        'trnLabel': trnLabelPreview,
        'itemHeader': itemHeaderPreview,
        'paidTextAlign': 'left',
        'amountRowsAlign': 'split',
      },
    );
    // #endregion

    return DefaultTextStyle.merge(
      style: mono,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _RawTicketPaper extends StatelessWidget {
  const _RawTicketPaper({required this.data});

  final ReceiptPreviewData data;

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: 11.5,
      height: 1.25,
      color: Colors.black87,
    );

    return DefaultTextStyle.merge(
      style: mono,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in data.rawLines)
            Text(
              line,
              style: mono,
              softWrap: false,
            ),
        ],
      ),
    );
  }
}
