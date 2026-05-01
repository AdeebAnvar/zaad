import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

class DayClosingScreen extends StatefulWidget {
  const DayClosingScreen({super.key});

  @override
  State<DayClosingScreen> createState() => _DayClosingScreenState();
}

class _DayClosingScreenState extends State<DayClosingScreen> {
  bool _loading = true;
  _DayClosingSummary _summary = _DayClosingSummary.empty();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = locator<AppDatabase>();
    final session = await db.sessionDao.getActiveSession();
    final orders = await db.ordersDao.getAllOrders();
    final branch = session == null ? null : await db.branchesDao.getBranchById(session.branchId);
    final users = await db.usersDao.getAllUsers();
    final items = await db.itemDao.getAll();

    final settled = orders.where((o) => o.status.toLowerCase() == 'completed').toList();
    final cancelled = orders.where((o) => o.status.toLowerCase() == 'cancelled').toList();
    final unpaid = orders
        .where((o) {
          final s = o.status.toLowerCase();
          return s != 'completed' && s != 'cancelled';
        })
        .toList();

    double sum(Iterable<Order> list, double Function(Order o) pick) => list.fold<double>(0, (acc, e) => acc + pick(e));

    final grossTotal = sum(settled, (o) => o.totalAmount);
    final discount = sum(settled, (o) => o.discountAmount);
    final netTotal = sum(settled, (o) => o.finalAmount);
    final cashSale = sum(settled, (o) => o.cashAmount);
    final cardSale = sum(settled, (o) => o.cardAmount);
    final creditSale = sum(settled, (o) => o.creditAmount);
    final onlineSale = sum(settled, (o) => o.onlineAmount);

    final dineInSales = sum(settled.where((o) => (o.orderType ?? '').toLowerCase() == 'dine_in'), (o) => o.finalAmount);
    final deliverySale = sum(
      settled.where((o) => (o.orderType ?? '').toLowerCase() == 'delivery'),
      (o) => o.finalAmount,
    );
    final takeAwaySale = sum(
      settled.where((o) {
        final t = (o.orderType ?? '').toLowerCase();
        return t.isEmpty || t == 'take_away';
      }),
      (o) => o.finalAmount,
    );
    final unpaidAmount = sum(unpaid, (o) => o.finalAmount);

    final openingCash = (branch?.openingCash ?? 0).toDouble();
    const creditRecovery = 0.0;
    const deliveryRecovery = 0.0;
    const purchase = 0.0; // no local purchase ledger table yet
    const salary = 0.0; // no local salary ledger table yet
    const otherIncome = 0.0; // no local income ledger table yet
    final expUnpaidTotal = purchase + salary + unpaidAmount - otherIncome;
    final cashIn = openingCash + cashSale;
    final cashOut = purchase + salary + unpaidAmount;
    final cashDrawer = cashIn - cashOut;
    final difference = expUnpaidTotal - cashDrawer;

    final typeRows = <_TypeSummaryRow>[
      _TypeSummaryRow(
        type: 'DINE-IN',
        count: settled.where((o) => (o.orderType ?? '').toLowerCase() == 'dine_in').length,
        discount: sum(settled.where((o) => (o.orderType ?? '').toLowerCase() == 'dine_in'), (o) => o.discountAmount),
        amount: dineInSales,
      ),
      _TypeSummaryRow(
        type: 'DELIVERY',
        count: settled.where((o) => (o.orderType ?? '').toLowerCase() == 'delivery').length,
        discount: sum(settled.where((o) => (o.orderType ?? '').toLowerCase() == 'delivery'), (o) => o.discountAmount),
        amount: deliverySale,
      ),
      _TypeSummaryRow(
        type: 'TAKEAWAY',
        count: settled.where((o) {
          final t = (o.orderType ?? '').toLowerCase();
          return t.isEmpty || t == 'take_away';
        }).length,
        discount: sum(
          settled.where((o) {
            final t = (o.orderType ?? '').toLowerCase();
            return t.isEmpty || t == 'take_away';
          }),
          (o) => o.discountAmount,
        ),
        amount: takeAwaySale,
      ),
    ];

    final collected = cashSale + cardSale + creditSale + onlineSale;
    final variance = collected - netTotal;
    final excessAmount = variance > 0 ? variance : 0.0;
    final shortAmount = variance < 0 ? -variance : 0.0;

    final itemById = {for (final i in items) i.id: i};
    final categoryMap = <String, _CategoryRow>{};
    for (final order in settled) {
      final lines = await db.cartsDao.getItemsByCart(order.cartId);
      for (final line in lines) {
        final item = itemById[line.itemId];
        final category = (item?.categoryName ?? 'UNCATEGORIZED').trim().isEmpty ? 'UNCATEGORIZED' : item!.categoryName.trim().toUpperCase();
        final existing = categoryMap[category];
        if (existing == null) {
          categoryMap[category] = _CategoryRow(category: category, qty: line.quantity, amount: line.total);
        } else {
          categoryMap[category] = _CategoryRow(
            category: existing.category,
            qty: existing.qty + line.quantity,
            amount: existing.amount + line.total,
          );
        }
      }
    }
    final categoryRows = categoryMap.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));

    final userById = {for (final u in users) u.id: u.name};
    final cancelledRows = cancelled
        .map(
          (o) => _CancelledRow(
            receiptId: o.invoiceNumber,
            reason: (o.referenceNumber ?? '').trim().isEmpty ? '—' : o.referenceNumber!.trim(),
            by: o.userId == null ? '—' : (userById[o.userId!] ?? 'User ${o.userId}'),
            amount: o.finalAmount,
          ),
        )
        .toList();

    if (!mounted) return;
    setState(() {
      _summary = _DayClosingSummary(
        generatedAt: DateTime.now(),
        lastClosingAt: settled.isEmpty ? null : settled.first.createdAt,
        grossTotal: grossTotal,
        discount: discount,
        netTotal: netTotal,
        openingCash: openingCash,
        cashSale: cashSale,
        cardSale: cardSale,
        creditSale: creditSale,
        onlineSale: onlineSale,
        creditRecovery: creditRecovery,
        dineInSales: dineInSales,
        deliverySale: deliverySale,
        takeAwaySales: takeAwaySale,
        deliveryRecovery: deliveryRecovery,
        purchase: purchase,
        salary: salary,
        otherIncome: otherIncome,
        cashIn: cashIn,
        cashOut: cashOut,
        cashDrawer: cashDrawer,
        unpaidAmount: unpaidAmount,
        difference: difference,
        excessAmount: excessAmount,
        shortAmount: shortAmount,
        typeRows: typeRows,
        categoryRows: categoryRows,
        cancelledRows: cancelledRows,
      );
      _loading = false;
    });
  }

  Future<void> _onPrint() async {
    try {
      final printService = locator<PrintService>();
      final rows = <({String label, double amount})>[
        (label: 'Opening Cash', amount: _summary.openingCash),
        (label: 'Cash Sale', amount: _summary.cashSale),
        (label: 'Card Sale', amount: _summary.cardSale),
        (label: 'Credit Sale', amount: _summary.creditSale),
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

  void _onSubmit() {
    if (_summary.unpaidAmount > 0.009) {
      CustomSnackBar.showWarning(
        message: 'Cannot settle day closing. Unpaid amount: ${RuntimeAppSettings.money(_summary.unpaidAmount)}',
      );
      return;
    }
    CustomSnackBar.showSuccess(message: 'Day closing submitted');
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
                          _row('CASH SALE', RuntimeAppSettings.money(_summary.cashSale)),
                          _row('CARD SALE', RuntimeAppSettings.money(_summary.cardSale)),
                          _row('CREDIT SALE', RuntimeAppSettings.money(_summary.creditSale)),
                          _row('DELIVERY SALE', RuntimeAppSettings.money(_summary.deliverySale)),
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
                          _row('UNPAID BILLS', RuntimeAppSettings.money(_summary.unpaidAmount)),
                          _row('SALARY', RuntimeAppSettings.money(_summary.salary)),
                          _row('OTHER INCOME (+)', RuntimeAppSettings.money(_summary.otherIncome), color: Colors.green.shade700),
                          _row(
                            'TOTAL (EXP + SAL + UNPAID – OTHER INCOME)',
                            RuntimeAppSettings.money(_summary.purchase + _summary.salary + _summary.unpaidAmount - _summary.otherIncome),
                            emphasize: true,
                          ),
                          _row(
                            'DIFFERENCE (TOTAL – CASH DRAWER)',
                            RuntimeAppSettings.money(_summary.difference),
                            color: Colors.cyan.shade700,
                            emphasize: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _sectionCard(
                        title: '4. Cash Reconciliation',
                        headers: const ['SOURCE', 'AMOUNT'],
                        rows: [
                          _row('OPENING CASH', RuntimeAppSettings.money(_summary.openingCash)),
                          _row('DINE-IN SALES', RuntimeAppSettings.money(_summary.dineInSales)),
                          _row('DELIVERY SALES', RuntimeAppSettings.money(_summary.deliverySale)),
                          _row('TAKEAWAY SALES', RuntimeAppSettings.money(_summary.takeAwaySales)),
                          _row('CASH IN (CASH SALE + OPENING)', RuntimeAppSettings.money(_summary.cashIn), emphasize: true),
                          _row('CASH OUT (EXP + SAL + UNPAID)', RuntimeAppSettings.money(_summary.cashOut), emphasize: true),
                        ],
                        footerLabel: 'TOTAL CASH DRAWER',
                        footerValue:
                            '${RuntimeAppSettings.money(_summary.cashDrawer)} ${_summary.difference > 0.009 ? '(SHORT YET)' : _summary.difference < -0.009 ? '(EXCESS)' : ''}',
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
                            : _summary.cancelledRows
                                .map((r) => [r.receiptId, r.reason, r.by, RuntimeAppSettings.money(r.amount)])
                                .toList(),
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
                              onPressed: () => _onPrint(),
                            ),
                            const SizedBox(width: 10),
                            CustomButton(
                              width: 96,
                              text: 'Submit',
                              onPressed: _onSubmit,
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

class _TypeSummaryRow {
  final String type;
  final int count;
  final double discount;
  final double amount;

  const _TypeSummaryRow({
    required this.type,
    required this.count,
    required this.discount,
    required this.amount,
  });
}

class _CategoryRow {
  final String category;
  final int qty;
  final double amount;

  const _CategoryRow({
    required this.category,
    required this.qty,
    required this.amount,
  });
}

class _CancelledRow {
  final String receiptId;
  final String reason;
  final String by;
  final double amount;

  const _CancelledRow({
    required this.receiptId,
    required this.reason,
    required this.by,
    required this.amount,
  });
}

class _DayClosingSummary {
  final DateTime generatedAt;
  final DateTime? lastClosingAt;
  final double grossTotal;
  final double discount;
  final double netTotal;
  final double openingCash;
  final double cashSale;
  final double cardSale;
  final double creditSale;
  final double onlineSale;
  final double creditRecovery;
  final double dineInSales;
  final double deliverySale;
  final double takeAwaySales;
  final double deliveryRecovery;
  final double purchase;
  final double salary;
  final double otherIncome;
  final double cashIn;
  final double cashOut;
  final double cashDrawer;
  final double unpaidAmount;
  final double difference;
  final double excessAmount;
  final double shortAmount;
  final List<_TypeSummaryRow> typeRows;
  final List<_CategoryRow> categoryRows;
  final List<_CancelledRow> cancelledRows;

  const _DayClosingSummary({
    required this.generatedAt,
    required this.lastClosingAt,
    required this.grossTotal,
    required this.discount,
    required this.netTotal,
    required this.openingCash,
    required this.cashSale,
    required this.cardSale,
    required this.creditSale,
    required this.onlineSale,
    required this.creditRecovery,
    required this.dineInSales,
    required this.deliverySale,
    required this.takeAwaySales,
    required this.deliveryRecovery,
    required this.purchase,
    required this.salary,
    required this.otherIncome,
    required this.cashIn,
    required this.cashOut,
    required this.cashDrawer,
    required this.unpaidAmount,
    required this.difference,
    required this.excessAmount,
    required this.shortAmount,
    required this.typeRows,
    required this.categoryRows,
    required this.cancelledRows,
  });

  factory _DayClosingSummary.empty() => _DayClosingSummary(
        generatedAt: DateTime.now(),
        lastClosingAt: null,
        grossTotal: 0,
        discount: 0,
        netTotal: 0,
        openingCash: 0,
        cashSale: 0,
        cardSale: 0,
        creditSale: 0,
        onlineSale: 0,
        creditRecovery: 0,
        dineInSales: 0,
        deliverySale: 0,
        takeAwaySales: 0,
        deliveryRecovery: 0,
        purchase: 0,
        salary: 0,
        otherIncome: 0,
        cashIn: 0,
        cashOut: 0,
        cashDrawer: 0,
        unpaidAmount: 0,
        difference: 0,
        excessAmount: 0,
        shortAmount: 0,
        typeRows: const [],
        categoryRows: const [],
        cancelledRows: const [],
      );
}
