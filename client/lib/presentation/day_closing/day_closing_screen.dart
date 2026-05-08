import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository_impl/settle_sale_push_mapper.dart';
import 'package:pos/presentation/day_closing/day_closing_summary.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

class DayClosingScreen extends StatefulWidget {
  const DayClosingScreen({super.key});

  @override
  State<DayClosingScreen> createState() => _DayClosingScreenState();
}

class _DayClosingScreenState extends State<DayClosingScreen> {
  bool _loading = true;
  bool _submitting = false;
  DayClosingSummary _summary = DayClosingSummary.empty();

  CounterAccess get _counterAccess => locator<CurrentCounterSession>().access;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    DayClosingSummary summary = DayClosingSummary.empty();
    try {
      final db = locator<AppDatabase>();
      summary = await computeDayClosingSummary(
        db,
        counterAccess: locator<CurrentCounterSession>().access,
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw TimeoutException('Day closing took too long'),
      );
    } on TimeoutException catch (e, st) {
      debugPrint('DayClosingScreen._load timeout: $e\n$st');
      summary = DayClosingSummary.empty();
      if (mounted) {
        CustomSnackBar.showWarning(
          message: 'Day closing is taking too long. Try again or reduce old orders.',
        );
      }
    } catch (e, st) {
      debugPrint('DayClosingScreen._load failed: $e\n$st');
      summary = DayClosingSummary.empty();
      if (mounted) {
        CustomSnackBar.showWarning(message: 'Could not load day closing data.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _summary = summary;
          _loading = false;
        });
      }
    }
  }

  Future<void> _onPrint() async {
    try {
      final printService = locator<PrintService>();
      final rows = <({String label, double amount})>[
        (label: 'Opening Cash', amount: _summary.openingCash),
        (label: 'Gross Sales', amount: _summary.grossTotal),
        if (_summary.totalVatAmount > 0.009) (label: 'Total VAT', amount: _summary.totalVatAmount),
        (label: 'Discounts', amount: _summary.discount),
        (label: 'Cash Sale', amount: _summary.cashSale),
        (label: 'Card Sale', amount: _summary.cardSale),
        (label: 'Credit Sale', amount: _summary.creditSale),
        (label: 'Online Sale', amount: _summary.onlineSale),
        (label: 'Delivery Sale', amount: _summary.deliverySale),
        (label: 'Net Sales', amount: _summary.netTotal),
        (label: 'Cash In', amount: _summary.cashIn),
        (label: 'Cash Out', amount: _summary.cashOut),
        (label: 'Cash Drawer', amount: _summary.cashDrawer),
        (label: 'Unpaid Amount', amount: _summary.unpaidAmount),
      ];
      final failed = await printService.printDayClosingReport(
        title: 'Day Closing',
        rows: rows,
      );
      if (!mounted) return;
      if (failed.isEmpty) {
        CustomSnackBar.showSuccess(message: 'Day closing sent to printer');
      } else {
        showPrintFailedDialog(context, failed);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorDialog(context, e);
    }
  }

  Future<bool> _confirmSubmitDayClosing() async {
    final result = await showAppConfirmDialog(
      context,
      title: 'Close day?',
      message: 'Are you sure you want to close the day?',
      cancelText: 'Cancel',
      confirmText: 'Yes, close day',
    );
    return result == true;
  }

  Future<void> _onSubmit() async {
    if (_submitting) return;
    if (_summary.unpaidAmount > 0.009) {
      CustomSnackBar.showWarning(
        message: 'Cannot settle day closing. Unpaid amount: ${RuntimeAppSettings.money(_summary.unpaidAmount)}',
      );
      return;
    }
    final ok = await _confirmSubmitDayClosing();
    if (!mounted || !ok) return;
    setState(() => _submitting = true);
    try {
      final db = locator<AppDatabase>();
      final summary = await computeDayClosingSummary(
        db,
        counterAccess: locator<CurrentCounterSession>().access,
      );
      if (!mounted) return;
      if (summary.unpaidAmount > 0.009) {
        CustomSnackBar.showWarning(
          message: 'Cannot settle day closing. Unpaid amount: ${RuntimeAppSettings.money(summary.unpaidAmount)}',
        );
        return;
      }

      final session = await db.sessionDao.getActiveSession();
      final branchId = session?.branchId ?? 1;
      final userId = session?.userId ?? 1;
      final uuid = const Uuid().v4();
      final at = DateTime.now();
      final payload = SettleSalePushMapper.buildSettleSalePayload(
        summary,
        uuid: uuid,
        branchId: branchId,
        userId: userId,
        at: at,
      );

      await db.settleSalesOutboxDao.insertPending(
        SettleSalesOutboxCompanion.insert(
          uuid: uuid,
          branchId: branchId,
          payloadJson: jsonEncode(payload),
        ),
      );
      final settledAt = DateTime.now();
      await db.dayClosingCheckpointDao.upsertLastSettledAt(branchId, settledAt);
      await db.branchesDao.updateOpeningCash(
        branchId: branchId,
        openingCashValue: 0,
      );
      if (!mounted) return;
      CustomSnackBar.showSuccess(message: 'Day closed successfully.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      showErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Day Closing',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'DAY CLOSING',
                        style: AppStyles.getBoldTextStyle(fontSize: 28, color: AppColors.textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last Closing date - ${_summary.lastClosingAt == null ? '—' : RuntimeAppSettings.formatDateTime(_summary.lastClosingAt!)}',
                        style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor),
                      ),
                      const SizedBox(height: 14),
                      _sectionCard(
                        title: '1. Opening Cash & Sales Details',
                        headers: const [' ', 'AMOUNT'],
                        rows: [
                          _row('OPENING CASH', RuntimeAppSettings.money(_summary.openingCash)),
                          _row('GROSS SALES (before discount)', RuntimeAppSettings.money(_summary.grossTotal)),
                          if (_summary.totalVatAmount > 0.009) _row('TOTAL VAT AMOUNT', RuntimeAppSettings.money(_summary.totalVatAmount)),
                          _row(
                            'DISCOUNTS',
                            RuntimeAppSettings.money(_summary.discount),
                            color: Colors.deepOrange.shade800,
                          ),
                          _row('NET SALES (completed)', RuntimeAppSettings.money(_summary.netTotal)),
                          _row('CASH SALE', RuntimeAppSettings.money(_summary.cashSale)),
                          _row('CARD SALE', RuntimeAppSettings.money(_summary.cardSale)),
                          _row('CREDIT SALE', RuntimeAppSettings.money(_summary.creditSale)),
                          _row('ONLINE SALE', RuntimeAppSettings.money(_summary.onlineSale)),
                          _row('DELIVERY SALE', RuntimeAppSettings.money(_summary.deliverySale)),
                          _row('CASH DRAWER BALANCE', RuntimeAppSettings.money(_summary.cashDrawer)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _sectionCard(
                        title: '2. Sales Summary & Adjustments',
                        headers: const ['TYPE', 'COUNT', 'DISCOUNT', 'AMOUNT'],
                        rows: [
                          ..._summary.typeRows.map((r) => [
                                r.type,
                                r.count.toString(),
                                RuntimeAppSettings.money(r.discount),
                                RuntimeAppSettings.money(r.amount),
                              ]),
                          _highlightRow('EXCESS AMOUNT', RuntimeAppSettings.money(_summary.excessAmount), isPositive: true),
                          _highlightRow('SHORT AMOUNT', RuntimeAppSettings.money(_summary.shortAmount), isPositive: false),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _sectionCard(
                        title: '3. Expense & Unpaid Reconciliation',
                        headers: const ['CATEGORY / UNPAID', 'AMOUNT'],
                        rows: [
                          _row('PURCHASE', RuntimeAppSettings.money(_summary.purchase)),
                          ..._unpaidBillRows(),
                          _row('SALARY', RuntimeAppSettings.money(_summary.salary)),
                          _row('OTHER INCOME (+)', RuntimeAppSettings.money(_summary.otherIncome), color: Colors.green.shade700),
                          _row(
                            'TOTAL (EXP + SAL + UNPAID – OTHER INCOME)',
                            RuntimeAppSettings.money(_summary.purchase + _summary.salary + _summary.unpaidAmount - _summary.otherIncome),
                            emphasize: true,
                          ),
                          _row(
                            'DIFFERENCE (SECTION 3 TOTAL − MODELED DRAWER)',
                            RuntimeAppSettings.money(_summary.difference.abs()),
                            color: Colors.cyan.shade700,
                            emphasize: true,
                          ),
                        ],
                      ),
                      if (_summary.openBills.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _sectionCard(
                          title: '3b. Open bills (settle these first)',
                          headers: const ['INVOICE', 'STATUS', 'TYPE', 'AMOUNT'],
                          rows: _summary.openBills
                              .map(
                                (r) => [
                                  r.invoiceNumber,
                                  r.status,
                                  _displayOrderTypeForClosing(r.orderType),
                                  RuntimeAppSettings.money(r.finalAmount),
                                ],
                              )
                              .toList(),
                          footerLabel: (_summary.unpaidAmount - _summary.unsettledFromAccessibleLogs).abs() <= 0.009 ? 'UNPAID TOTAL' : 'UNPAID TOTAL (YOUR LOGS)',
                          footerValue: RuntimeAppSettings.money(_summary.unsettledFromAccessibleLogs),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _sectionCard(
                        title: '4. Cash Reconciliation',
                        headers: const ['SOURCE', 'AMOUNT'],
                        rows: [
                          _row('OPENING CASH', RuntimeAppSettings.money(_summary.openingCash)),
                          _row('DINE-IN SALES', RuntimeAppSettings.money(_summary.dineInSales)),
                          _row('DELIVERY SALES', RuntimeAppSettings.money(_summary.deliverySale)),
                          _row('TAKEAWAY SALES', RuntimeAppSettings.money(_summary.takeAwaySales)),
                          _row('CASH IN (OPENING + CASH SALE AFTER DISCOUNT)', RuntimeAppSettings.money(_summary.cashIn), emphasize: true),
                          _row('CASH OUT (EXPENSES FROM CASH)', RuntimeAppSettings.money(_summary.cashOut), emphasize: true),
                        ],
                        footerLabel: 'TOTAL CASH DRAWER',
                        footerValue: '${RuntimeAppSettings.money(_summary.cashDrawer)} ${_cashDrawerVarianceHint(_summary.difference)}',
                      ),
                      const SizedBox(height: 14),
                      _sectionCard(
                        title: '5. Category Wise Product List',
                        headers: const ['CATEGORY', 'QTY', 'AMOUNT'],
                        rows: [
                          ..._summary.categoryRows.map((r) => [
                                r.category,
                                r.qty.toString(),
                                RuntimeAppSettings.money(r.amount),
                              ]),
                        ],
                        footerLabel: 'GRAND TOTAL',
                        footerValue: RuntimeAppSettings.money(_summary.netTotal),
                      ),
                      const SizedBox(height: 14),
                      _sectionCard(
                        title: '7. Cancelled Bills Summary',
                        headers: const ['RECEIPT ID', 'REASON', 'BY', 'AMOUNT'],
                        rows: _summary.cancelledRows.isEmpty
                            ? [
                                [' ', 'NO CANCELLED BILLS RECORDED.', ' ', ' ']
                              ]
                            : _summary.cancelledRows.map((r) => [r.receiptId, r.reason, r.by, RuntimeAppSettings.money(r.amount)]).toList(),
                        footerLabel: 'TOTAL CANCELLED (${_summary.cancelledRows.length})',
                        footerValue: RuntimeAppSettings.money(_summary.cancelledRows.fold<double>(0, (s, e) => s + e.amount)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CustomButton(
                              width: 92,
                              text: 'Print',
                              onPressed: _submitting ? null : () => _onPrint(),
                            ),
                            const SizedBox(width: 10),
                            CustomButton(
                              width: 96,
                              text: 'Submit',
                              isLoading: _submitting,
                              onPressed: () => unawaited(_onSubmit()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// One “UNPAID BILLS” row for admins (or when branch-wide matches visible); otherwise splits by log permission.
  List<List<String>> _unpaidBillRows() {
    final gap = (_summary.unpaidAmount - _summary.unsettledFromAccessibleLogs).abs();
    final split = !_counterAccess.isAdmin && gap > 0.009;
    if (!split) {
      return [_row('UNPAID BILLS', RuntimeAppSettings.money(_summary.unpaidAmount))];
    }
    return [
      _row(
        'UNPAID BILLS (logs you can open)',
        RuntimeAppSettings.money(_summary.unsettledFromAccessibleLogs),
      ),
      _row(
        'UNPAID (channels without log permission)',
        RuntimeAppSettings.money(_summary.unpaidAmount - _summary.unsettledFromAccessibleLogs),
        color: Colors.deepOrange.shade800,
      ),
    ];
  }

  /// Plain label for modeled drawer vs Section 3 expense/unpaid TOTAL (see hint below that card).
  String _cashDrawerVarianceHint(double difference) {
    if (difference > 0.009) return '(SHORT vs Section 3 expense total)';
    if (difference < -0.009) return '(EXCESS vs Section 3 expense total)';
    return '';
  }

  String _displayOrderTypeForClosing(String? t) {
    final s = (t ?? '').trim().toLowerCase();
    if (s.isEmpty || s == 'take_away') return 'Take away';
    if (s == 'dine_in') return 'Dine-in';
    if (s == 'delivery') return 'Delivery';
    return (t ?? '').trim();
  }

  List<String> _row(String label, String value, {Color? color, bool emphasize = false}) {
    if (color != null || emphasize) {
      return ['__STYLE__', label, value, '${color?.toARGB32() ?? 0}', emphasize ? '1' : '0'];
    }
    return [label, value];
  }

  List<String> _highlightRow(String label, String value, {required bool isPositive}) {
    return ['__HIGHLIGHT__', label, value, isPositive ? '1' : '0'];
  }

  Widget _sectionCard({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    String? footerLabel,
    String? footerValue,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.getBoldTextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          _tableHeader(headers),
          ...rows.map((r) => _tableRow(headers.length, r)),
          if (footerLabel != null && footerValue != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      footerLabel,
                      style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                  Text(
                    footerValue,
                    style: AppStyles.getSemiBoldTextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> headers) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: headers
            .map(
              (h) => Expanded(
                child: Text(
                  h,
                  textAlign: h == headers.first ? TextAlign.left : TextAlign.right,
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 12, color: AppColors.textColor),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _tableRow(int columnCount, List<String> r) {
    final isStyled = r.isNotEmpty && r.first == '__STYLE__';
    final isHighlight = r.isNotEmpty && r.first == '__HIGHLIGHT__';

    late final List<String> data;
    Color rowColor = const Color(0xFFF5F6F8);
    Color textColor = AppColors.textColor;
    FontWeight weight = FontWeight.w600;

    if (isStyled) {
      data = [r[1], r[2]];
      final colorVal = int.tryParse(r[3]) ?? 0;
      final emphasize = r[4] == '1';
      if (colorVal != 0) textColor = Color(colorVal);
      if (emphasize) weight = FontWeight.w700;
    } else if (isHighlight) {
      data = [r[1], r[2]];
      final positive = r[3] == '1';
      textColor = positive ? Colors.green.shade700 : Colors.red.shade700;
      rowColor = positive ? Colors.green.withValues(alpha: 0.06) : Colors.red.withValues(alpha: 0.06);
      weight = FontWeight.w700;
    } else {
      data = r;
    }

    final values = data.length == columnCount ? data : [...data, ...List.filled(columnCount - data.length, '')];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: List.generate(
          columnCount,
          (i) => Expanded(
            child: Text(
              values[i],
              textAlign: i == 0 ? TextAlign.left : TextAlign.right,
              style: AppStyles.getSemiBoldTextStyle(
                fontSize: 13,
                color: textColor,
              ).copyWith(fontWeight: weight),
            ),
          ),
        ),
      ),
    );
  }
}
