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
  _DayClosingSummary _summary = const _DayClosingSummary.empty();

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

    final settled = orders.where((o) => o.status.toLowerCase() == 'completed').toList();
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
    final deliverySale = sum(
      settled.where((o) => (o.orderType ?? '').toLowerCase() == 'delivery'),
      (o) => o.finalAmount,
    );
    final unpaidAmount = sum(unpaid, (o) => o.finalAmount);

    final openingCash = (branch?.openingCash ?? 0).toDouble();
    const creditRecovery = 0.0;
    const deliveryRecovery = 0.0;
    const payback = 0.0;
    const expense = 0.0;
    final cashDrawer = openingCash + cashSale + creditRecovery + deliveryRecovery - payback - expense;

    if (!mounted) return;
    setState(() {
      _summary = _DayClosingSummary(
        grossTotal: grossTotal,
        discount: discount,
        netTotal: netTotal,
        openingCash: openingCash,
        cashSale: cashSale,
        cardSale: cardSale,
        creditSale: creditSale,
        onlineSale: onlineSale,
        creditRecovery: creditRecovery,
        deliverySale: deliverySale,
        deliveryRecovery: deliveryRecovery,
        payback: payback,
        expense: expense,
        cashDrawer: cashDrawer,
        unpaidAmount: unpaidAmount,
      );
      _loading = false;
    });
  }

  Future<void> _onPrint() async {
    try {
      final printService = locator<PrintService>();
      final rows = <({String label, double amount})>[
        (label: 'Gross Total', amount: _summary.grossTotal),
        (label: 'Discount', amount: -_summary.discount),
        (label: 'Net Total', amount: _summary.netTotal),
        (label: 'Cash At Starting', amount: _summary.openingCash),
        (label: 'Total Cash Sale', amount: _summary.cashSale),
        (label: 'Total Card Sale', amount: _summary.cardSale),
        (label: 'Total Credit Sale', amount: _summary.creditSale),
        (label: 'Total Online Sale', amount: _summary.onlineSale),
        (label: 'Credit Recovery', amount: _summary.creditRecovery),
        (label: 'Delivery Sale', amount: _summary.deliverySale),
        (label: 'Delivery Recovery', amount: _summary.deliveryRecovery),
        (label: 'Payback', amount: _summary.payback),
        (label: 'Expense', amount: _summary.expense),
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
                      _summaryCard(
                        rows: [
                          ('Gross Total', _summary.grossTotal),
                          ('Discount', -_summary.discount),
                          ('Net Total', _summary.netTotal),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _summaryCard(
                        rows: [
                          ('Cash at Starting', _summary.openingCash),
                          ('Total Cash Sale', _summary.cashSale),
                          ('Total Card Sale', _summary.cardSale),
                          ('Total Credit Sale', _summary.creditSale),
                          ('Total Online Sale', _summary.onlineSale),
                          ('Credit Recovery', _summary.creditRecovery),
                          ('Delivery Sale', _summary.deliverySale),
                          ('Delivery Recovery', _summary.deliveryRecovery),
                          ('Payback', _summary.payback),
                          ('Expense', _summary.expense),
                          ('Cash Drawer', _summary.cashDrawer),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_summary.unpaidAmount > 0.009)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            'Unpaid amount pending: ${RuntimeAppSettings.money(_summary.unpaidAmount)}',
                            style: AppStyles.getMediumTextStyle(fontSize: 13, color: Colors.orange.shade900),
                          ),
                        ),
                      const SizedBox(height: 14),
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

  Widget _summaryCard({required List<(String, double)> rows}) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        children: rows
            .map(
              (r) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.$1.toUpperCase(),
                        style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: AppColors.textColor),
                      ),
                    ),
                    Text(
                      RuntimeAppSettings.money(r.$2),
                      style: AppStyles.getSemiBoldTextStyle(fontSize: 13.5, color: AppColors.textColor),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DayClosingSummary {
  final double grossTotal;
  final double discount;
  final double netTotal;
  final double openingCash;
  final double cashSale;
  final double cardSale;
  final double creditSale;
  final double onlineSale;
  final double creditRecovery;
  final double deliverySale;
  final double deliveryRecovery;
  final double payback;
  final double expense;
  final double cashDrawer;
  final double unpaidAmount;

  const _DayClosingSummary({
    required this.grossTotal,
    required this.discount,
    required this.netTotal,
    required this.openingCash,
    required this.cashSale,
    required this.cardSale,
    required this.creditSale,
    required this.onlineSale,
    required this.creditRecovery,
    required this.deliverySale,
    required this.deliveryRecovery,
    required this.payback,
    required this.expense,
    required this.cashDrawer,
    required this.unpaidAmount,
  });

  const _DayClosingSummary.empty()
      : grossTotal = 0,
        discount = 0,
        netTotal = 0,
        openingCash = 0,
        cashSale = 0,
        cardSale = 0,
        creditSale = 0,
        onlineSale = 0,
        creditRecovery = 0,
        deliverySale = 0,
        deliveryRecovery = 0,
        payback = 0,
        expense = 0,
        cashDrawer = 0,
        unpaidAmount = 0;
}

