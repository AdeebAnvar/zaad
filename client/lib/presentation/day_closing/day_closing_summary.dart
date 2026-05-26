import 'package:flutter/foundation.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/utils/credit_payment_metadata.dart';
import 'package:pos/core/utils/order_log_cart_fallback.dart';
import 'package:pos/core/utils/order_payment_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/branch_model.dart';
import 'package:pos/domain/models/financial_record_type.dart';
import 'package:pos/domain/models/user_model.dart';

double _sumOrders(Iterable<Order> list, double Function(Order o) pick) =>
    list.fold<double>(0, (acc, e) => acc + pick(e));

double _cashSaleAfterDiscount(Iterable<Order> settled, double Function(Order o) effectiveOrderDiscount) {
  var total = 0.0;
  for (final o in settled) {
    final cash = o.cashAmount;
    if (cash <= 0.009) continue;
    final paid = o.cashAmount + o.cardAmount + o.creditAmount + o.onlineAmount;
    if (paid <= 0.009) {
      total += cash;
      continue;
    }
    final discount = effectiveOrderDiscount(o).clamp(0, o.totalAmount).toDouble();
    final cashShare = (cash / paid).clamp(0.0, 1.0);
    final discountFromCash = discount * cashShare;
    final netCash = (cash - discountFromCash).clamp(0.0, cash).toDouble();
    total += netCash;
  }
  return total;
}

/// Normalizes order-level discount. Supports amount/percentage and falls back to total-final gap.
double _orderLevelDiscount(Order o) {
  final t = (o.discountType ?? '').trim().toLowerCase();
  if (o.discountAmount > 0.009) {
    if (t == 'percentage') {
      final pct = o.discountAmount.clamp(0, 100).toDouble();
      final computed = (o.totalAmount * pct / 100).clamp(0, o.totalAmount).toDouble();
      final gap = (o.totalAmount - o.finalAmount).toDouble();
      final validGap = gap > 0.009 ? gap : 0.0;
      if (validGap > 0 && (computed - validGap).abs() > 0.02) {
        // Legacy-compat: old records sometimes stored discount amount with `discountType=percentage`.
        // For day-closing amount reporting, trust the actual billed gap when values materially disagree.
        return validGap;
      }
      return computed;
    }
    return o.discountAmount;
  }
  final gap = o.totalAmount - o.finalAmount;
  return gap > 0.009 ? gap : 0.0;
}

/// Sum of saved line-level discount amounts (already excluded from each line's [CartItem.total]).
double _lineDiscountSum(Iterable<CartItem> lines) {
  var sum = 0.0;
  for (final line in lines) {
    final d = line.discount;
    if (d > 0.009) sum += d;
  }
  return sum;
}

String _categoryLabelForLine(CartItem line, Item? item, Map<int, String> categoryNameByCatId) {
  var cn = (item?.categoryName ?? '').trim();
  if (cn.isEmpty && item != null) {
    cn = (categoryNameByCatId[item.categoryId] ?? '').trim();
  }
  if (cn.isEmpty) {
    final name = line.itemName.trim();
    return name.isNotEmpty ? name.toUpperCase() : 'UNCATEGORIZED';
  }
  return cn.toUpperCase();
}

/// True when the order still owes money (matches dine-in / delivery log pay rules).
bool orderHasOutstandingBalance(Order o, {double tolerance = 0.02}) {
  final payable = o.finalAmount > 0.009 ? o.finalAmount : o.totalAmount;
  if (payable <= 0.009) return false;
  final paid = o.cashAmount + o.cardAmount + o.creditAmount + o.onlineAmount;
  return paid + tolerance < payable;
}

/// Open bill for day-close submit gate: not closed/cancelled and balance still owed.
/// Fully paid rows with status still `pending`/`kot` (common on delivery) are not unsettled.
bool _isUnsettledForDayClose(Order o) {
  final s = o.status.toLowerCase();
  if (s == 'completed' || s == 'cancelled') return false;
  return orderHasOutstandingBalance(o);
}

/// Sales rows for day closing should include paid orders even when status is not yet `completed`.
/// (Some flows keep delivery / edited orders in `pending` while payment is already recorded.)
bool _isSettledForDayClose(Order o) {
  final s = o.status.toLowerCase();
  if (s == 'cancelled' || s == 'kot') return false;
  if (s == 'completed') return true;
  final payable = o.finalAmount > 0.009 ? o.finalAmount : o.totalAmount;
  if (payable <= 0.009) return false;
  final paid = o.cashAmount + o.cardAmount + o.creditAmount + o.onlineAmount;
  return paid + 0.02 >= payable;
}

/// Whether this unsettled order belongs to a **log** channel the user may open.
bool _unsettledMatchesUserLogAccess(Order o, CounterAccess access) {
  if (access.isAdmin) return true;
  final t = (o.orderType ?? '').trim().toLowerCase();
  if (t.isEmpty || t == 'take_away') {
    return access.canTakeAwayLog;
  }
  if (t == 'dine_in') {
    return access.canDineInLog;
  }
  if (t == 'delivery') {
    return access.canDeliveryLog;
  }
  return access.canTakeAwayLog || access.canDineInLog || access.canDeliveryLog;
}

/// Shared aggregates for day closing UI, thermal print, and `settle_sales` push payload
/// ([SettleSalePushMapper]).
class DayClosingSummary {
  final DateTime generatedAt;
  final DateTime? lastClosingAt;
  final double grossTotal;
  final double totalVatAmount;
  final double discount;
  final double netTotal;
  final double openingCash;
  /// Branch default opening balance (from server / saved in drawer).
  final double defaultOpeningCash;
  /// Net cash from settled orders after allocated discounts (same basis as [cashIn] minus [openingCash]).
  final double cashSaleAfterDiscount;
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
  /// Branch-wide unsettled total (all channels). Drives submit gate, cash reconciliation, and cloud payload.
  final double unpaidAmount;
  /// Unsettled total for orders whose logs this user may access (take away / dine-in / delivery).
  /// Matches [unpaidAmount] when [CounterAccess.isAdmin].
  final double unsettledFromAccessibleLogs;
  /// Sum of [Order.creditAmount] on unpaid orders (completed/cancelled excluded; dine-in `kot` excluded).
  final double outstandingCredit;
  final double difference;
  final double excessAmount;
  final double shortAmount;
  /// Per payment channel (CASH, CARD, CREDIT, ONLINE) before manual close reconciliation.
  final List<DayClosingPaymentVariance> paymentVariances;
  final List<DayClosingTypeSummaryRow> typeRows;
  final List<DayClosingCategoryRow> categoryRows;
  final List<DayClosingCancelledRow> cancelledRows;
  /// Open bills the user may review (same log permissions as [unsettledFromAccessibleLogs]).
  final List<DayClosingOpenBill> openBills;
  final List<DayClosingOtherIncomeRow> otherIncomeRows;

  const DayClosingSummary({
    required this.generatedAt,
    required this.lastClosingAt,
    required this.grossTotal,
    required this.totalVatAmount,
    required this.discount,
    required this.netTotal,
    required this.openingCash,
    required this.defaultOpeningCash,
    required this.cashSaleAfterDiscount,
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
    required this.unsettledFromAccessibleLogs,
    required this.outstandingCredit,
    required this.difference,
    required this.excessAmount,
    required this.shortAmount,
    required this.paymentVariances,
    required this.typeRows,
    required this.categoryRows,
    required this.cancelledRows,
    required this.openBills,
    required this.otherIncomeRows,
  });

  factory DayClosingSummary.empty() => DayClosingSummary(
        generatedAt: DateTime.now(),
        lastClosingAt: null,
        grossTotal: 0,
        totalVatAmount: 0,
        discount: 0,
        netTotal: 0,
        openingCash: 0,
        defaultOpeningCash: 0,
        cashSaleAfterDiscount: 0,
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
        unsettledFromAccessibleLogs: 0,
        outstandingCredit: 0,
        difference: 0,
        excessAmount: 0,
        shortAmount: 0,
        paymentVariances: const [],
        typeRows: const [],
        categoryRows: const [],
        cancelledRows: const [],
        openBills: const [],
        otherIncomeRows: const [],
      );
}

class DayClosingOtherIncomeRow {
  final String description;
  final String payment;
  final double amount;
  final DateTime createdAt;

  const DayClosingOtherIncomeRow({
    required this.description,
    required this.payment,
    required this.amount,
    required this.createdAt,
  });
}

class DayClosingOpenBill {
  final String invoiceNumber;
  final String status;
  final String? orderType;
  final String? customerName;
  final double balanceDue;
  final DateTime createdAt;

  const DayClosingOpenBill({
    required this.invoiceNumber,
    required this.status,
    required this.orderType,
    required this.customerName,
    required this.balanceDue,
    required this.createdAt,
  });
}

class DayClosingTypeSummaryRow {
  final String type;
  final int count;
  final double discount;
  final double amount;

  const DayClosingTypeSummaryRow({
    required this.type,
    required this.count,
    required this.discount,
    required this.amount,
  });
}

class DayClosingCategoryRow {
  final String category;
  final int qty;
  final double amount;

  const DayClosingCategoryRow({
    required this.category,
    required this.qty,
    required this.amount,
  });
}

class DayClosingCancelledRow {
  final String receiptId;
  final String reason;
  final String by;
  final double amount;

  const DayClosingCancelledRow({
    required this.receiptId,
    required this.reason,
    required this.by,
    required this.amount,
  });
}

/// Excess or short for one payment channel (CASH, CARD, CREDIT, ONLINE).
class DayClosingPaymentVariance {
  const DayClosingPaymentVariance({
    required this.channel,
    required this.excess,
    required this.short,
  });

  final String channel;
  final double excess;
  final double short;
}

/// Opening staff reconciliation: manual excess/short per channel at day close.
class DayClosingCloseReconciliation {
  const DayClosingCloseReconciliation({
    required this.cashExpected,
    required this.cashExcess,
    required this.cashShort,
    required this.cardExpected,
    required this.cardExcess,
    required this.cardShort,
    required this.creditExpected,
    required this.creditExcess,
    required this.creditShort,
    required this.onlineExpected,
    required this.onlineExcess,
    required this.onlineShort,
  });

  final double cashExpected;
  final double cashExcess;
  final double cashShort;
  final double cardExpected;
  final double cardExcess;
  final double cardShort;
  final double creditExpected;
  final double creditExcess;
  final double creditShort;
  final double onlineExpected;
  final double onlineExcess;
  final double onlineShort;

  double get actualCash => cashExpected + cashExcess - cashShort;
  double get actualCard => cardExpected + cardExcess - cardShort;
  double get actualCredit => creditExpected + creditExcess - creditShort;
  double get actualOnline => onlineExpected + onlineExcess - onlineShort;

  double get totalExcess => cashExcess + cardExcess + creditExcess + onlineExcess;
  double get totalShort => cashShort + cardShort + creditShort + onlineShort;

  List<DayClosingPaymentVariance> get paymentVariances => <DayClosingPaymentVariance>[
        DayClosingPaymentVariance(channel: 'CASH', excess: cashExcess, short: cashShort),
        DayClosingPaymentVariance(channel: 'CARD', excess: cardExcess, short: cardShort),
        DayClosingPaymentVariance(channel: 'CREDIT', excess: creditExcess, short: creditShort),
        DayClosingPaymentVariance(channel: 'ONLINE', excess: onlineExcess, short: onlineShort),
      ];
}

/// UI / print tolerance for rounding “non-zero” excess or short rows.
const double kDayCloseAmountTolerance = 0.009;

double effectiveDayClosingCashIn(
  DayClosingSummary summary, {
  DayClosingCloseReconciliation? closeReconciliation,
}) {
  final recon = closeReconciliation;
  if (recon == null) return summary.cashIn;
  return summary.openingCash + recon.actualCash + summary.otherIncome;
}

double effectiveDayClosingCashDrawer(
  DayClosingSummary summary, {
  DayClosingCloseReconciliation? closeReconciliation,
}) {
  final recon = closeReconciliation;
  if (recon == null) return summary.cashDrawer;
  final cashIn = effectiveDayClosingCashIn(summary, closeReconciliation: recon);
  return cashIn - summary.cashOut;
}

double effectiveDayClosingDifference(
  DayClosingSummary summary, {
  DayClosingCloseReconciliation? closeReconciliation,
}) {
  final section3Total =
      summary.purchase + summary.salary + summary.unpaidAmount - summary.otherIncome;
  final drawer =
      effectiveDayClosingCashDrawer(summary, closeReconciliation: closeReconciliation);
  return section3Total - drawer;
}

List<DayClosingPaymentVariance> effectiveDayClosingPaymentVariances(
  DayClosingSummary summary, {
  DayClosingCloseReconciliation? closeReconciliation,
}) {
  if (closeReconciliation != null) {
    return closeReconciliation.paymentVariances;
  }
  return summary.paymentVariances;
}

List<DayClosingPaymentVariance> orderedDayClosingPaymentVariances(
  DayClosingSummary summary, {
  DayClosingCloseReconciliation? closeReconciliation,
}) {
  final vs =
      effectiveDayClosingPaymentVariances(summary, closeReconciliation: closeReconciliation);
  const order = ['CASH', 'CARD', 'CREDIT', 'ONLINE'];
  final idx = {for (var i = 0; i < order.length; i++) order[i]: i};
  final out = [...vs];
  out.sort((a, b) => (idx[a.channel] ?? 99).compareTo(idx[b.channel] ?? 99));
  return out;
}

const _varianceTol = 0.009;

/// Splits collected-vs-net variance across payment channels proportionally.
List<DayClosingPaymentVariance> computeSystemPaymentVariances({
  required double cashExpected,
  required double cardExpected,
  required double creditExpected,
  required double onlineExpected,
  required double netTotal,
}) {
  final channels = <(String, double)>[
    ('CASH', cashExpected),
    ('CARD', cardExpected),
    ('CREDIT', creditExpected),
    ('ONLINE', onlineExpected),
  ];
  final collected =
      cashExpected + cardExpected + creditExpected + onlineExpected;
  if (collected <= _varianceTol) {
    return channels
        .map(
          (c) => DayClosingPaymentVariance(channel: c.$1, excess: 0, short: 0),
        )
        .toList();
  }
  return [
    for (final c in channels)
      () {
        final share = c.$2 / collected;
        final allocatedNet = share * netTotal;
        final delta = c.$2 - allocatedNet;
        return DayClosingPaymentVariance(
          channel: c.$1,
          excess: delta > _varianceTol ? delta : 0,
          short: delta < -_varianceTol ? -delta : 0,
        );
      }(),
  ];
}

List<Order> _ordersForCashierScope(List<Order> orders, int? cashierUserId) {
  if (cashierUserId == null) return orders;
  return orders.where((o) => o.userId == cashierUserId).toList();
}

// ── isolate-safe data bundle for the computation pass ───────────────────────

class _DayClosingComputeInput {
  const _DayClosingComputeInput({
    required this.rawOrders,
    required this.cutoff,
    required this.branch,
    required this.users,
    required this.visibleItems,
    required this.categoryNameByCatId,
    required this.linesByOrderId,
    required this.counterAccess,
    required this.missingItemsById,
    required this.purchase,
    required this.salary,
    required this.otherIncomeRows,
  });

  final List<Order> rawOrders;
  final DateTime? cutoff;
  final BranchModel? branch;
  final List<UserModel> users;
  final List<Item> visibleItems;
  final Map<int, String> categoryNameByCatId;
  final Map<int, List<CartItem>> linesByOrderId;
  final CounterAccess counterAccess;
  final Map<int, Item> missingItemsById;
  final double purchase;
  final double salary;
  final List<DayClosingOtherIncomeRow> otherIncomeRows;
}

DayClosingSummary _computeSummarySync(_DayClosingComputeInput i) {
  final rawOrders = i.rawOrders;
  final cutoff = i.cutoff;
  final branch = i.branch;
  final users = i.users;
  final visibleItems = i.visibleItems;
  final categoryNameByCatId = i.categoryNameByCatId;
  final linesByOrderId = i.linesByOrderId;
  final counterAccess = i.counterAccess;
  final missingItemsById = i.missingItemsById;

  final ordersInWindow = cutoff == null
      ? rawOrders
      : rawOrders.where((o) => orderInDayCloseWindow(o, cutoff)).toList();

  final settledAll = ordersInWindow.where(_isSettledForDayClose).toList();
  /// New sales in this period (exclude post-close credit collections from revenue breakdown).
  final settled = settledAll.where((o) => orderCreatedInDayCloseWindow(o, cutoff)).toList();
  final settledRecovery =
      settledAll.where((o) => !orderCreatedInDayCloseWindow(o, cutoff)).toList();
  /// Ignore checkpoint — show all cancelled rows still stored locally (same branch).
  final cancelled =
      rawOrders.where((o) => o.status.toLowerCase() == 'cancelled').toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  /// Ignore checkpoint — see comment on [computeDayClosingSummary].
  final unpaidBranchList = rawOrders.where(_isUnsettledForDayClose).toList();
  final unpaidVisible =
      unpaidBranchList.where((o) => _unsettledMatchesUserLogAccess(o, counterAccess)).toList();
  // [Order.totalAmount] is the sum of line totals; each line total already excludes [CartItem.discount].
  //
  // Day-closing discount reporting must include:
  // - Item-wise: summed from [CartItem.discount] (see [lineDiscountForOrder]).
  // - Cart-wise + offers: anything that reduced [Order.finalAmount] below [Order.totalAmount].
  //
  // Cart checkout merges manual cart discount and offer into [Order.discountAmount], but if that
  // field under-reports vs the billed gap, trust (totalAmount − finalAmount) so offers are not lost.
  double effectiveOrderDiscount(Order o) {
    final normalized = _orderLevelDiscount(o).clamp(0.0, o.totalAmount).toDouble();
    final gap = (o.totalAmount - o.finalAmount).clamp(0.0, o.totalAmount).toDouble();
    if (gap > normalized + 0.02) return gap;
    return normalized;
  }
  double effectiveOrderNet(Order o) =>
      (o.totalAmount - effectiveOrderDiscount(o)).clamp(0.0, o.totalAmount).toDouble();

  double lineDiscountForOrder(Order o) =>
      _lineDiscountSum(linesByOrderId[o.id] ?? const <CartItem>[]);

  final orderDiscount = _sumOrders(settled, effectiveOrderDiscount);
  final lineItemDiscount = _sumOrders(settled, lineDiscountForOrder);
  final discount = orderDiscount + lineItemDiscount;
  final netTotal = _sumOrders(settled, effectiveOrderNet);
  // Gross = net + all discounts (line-level + order-level) so UI "before discount" matches receipts.
  final grossTotal = netTotal + discount;
  final vatMode = (branch?.vat ?? '').trim().toLowerCase();
  final vp = branch?.vatPercent;
  final vatPct = vp is num ? vp.toDouble() : double.tryParse('$vp') ?? 0.0;
  final totalVatAmount = (vatMode.isNotEmpty && vatMode != 'no_vat' && vatPct > 0)
      ? (netTotal - (netTotal / (1 + vatPct / 100.0)))
      : 0.0;
  var recoveryCash = 0.0;
  var recoveryCard = 0.0;
  var recoveryOnline = 0.0;
  if (cutoff != null) {
    for (final o in settledRecovery) {
      final r = creditRecoveryAfterCheckpoint(o, cutoff);
      recoveryCash += r.cash;
      recoveryCard += r.card;
      recoveryOnline += r.online;
    }
  }
  final cashSale = _sumOrders(settled, (o) => o.cashAmount) + recoveryCash;
  final cashSaleAfterDiscount =
      _cashSaleAfterDiscount(settled, effectiveOrderDiscount) + recoveryCash;
  final cardSale = _sumOrders(settled, (o) => o.cardAmount) + recoveryCard;
  final creditSale = _sumOrders(settled, (o) => o.creditAmount);
  final onlineSale = _sumOrders(settled, (o) => o.onlineAmount) + recoveryOnline;
  final creditRecovery = recoveryCash + recoveryCard + recoveryOnline;

  final dineInSales = _sumOrders(
    settled.where((o) => (o.orderType ?? '').toLowerCase() == 'dine_in'),
    effectiveOrderNet,
  );
  final deliverySale = _sumOrders(
    settled.where((o) => (o.orderType ?? '').toLowerCase() == 'delivery'),
    effectiveOrderNet,
  );
  final takeAwaySale = _sumOrders(
    settled.where((o) {
      final t = (o.orderType ?? '').toLowerCase();
      return t.isEmpty || t == 'take_away';
    }),
    effectiveOrderNet,
  );
  final unpaidAmount = _sumOrders(unpaidBranchList, orderBalanceDue);
  final unsettledFromAccessibleLogs =
      _sumOrders(unpaidVisible, orderBalanceDue);
  final outstandingCredit = _sumOrders(unpaidBranchList, (o) => o.creditAmount);

  final openingBalance = (branch?.effectiveOpeningBalance() ?? 0).toDouble();
  final openingCash = openingBalance;
  final defaultOpeningCash = openingBalance;
  const deliveryRecovery = 0.0;
  final purchase = i.purchase;
  final salary = i.salary;
  final otherIncomeRows = i.otherIncomeRows;
  final otherIncome =
      otherIncomeRows.fold<double>(0, (double s, DayClosingOtherIncomeRow r) => s + r.amount);
  final expUnpaidTotal = purchase + salary + unpaidAmount - otherIncome;
  // Modeled drawer: opening + net cash sales + other income (cash in) − expenses from cash.
  final cashIn = openingCash + cashSaleAfterDiscount + otherIncome;
  final cashOut = purchase + salary;
  final cashDrawer = cashIn - cashOut;
  final difference = expUnpaidTotal - cashDrawer;

  final typeRows = <DayClosingTypeSummaryRow>[
    DayClosingTypeSummaryRow(
      type: 'DINE-IN',
      count: settled.where((o) => (o.orderType ?? '').toLowerCase() == 'dine_in').length,
      discount: _sumOrders(
        settled.where((o) => (o.orderType ?? '').toLowerCase() == 'dine_in'),
        (o) => effectiveOrderDiscount(o) + lineDiscountForOrder(o),
      ),
      amount: dineInSales,
    ),
    DayClosingTypeSummaryRow(
      type: 'DELIVERY',
      count:
          settled.where((o) => (o.orderType ?? '').toLowerCase() == 'delivery').length,
      discount: _sumOrders(
        settled.where((o) => (o.orderType ?? '').toLowerCase() == 'delivery'),
        (o) => effectiveOrderDiscount(o) + lineDiscountForOrder(o),
      ),
      amount: deliverySale,
    ),
    DayClosingTypeSummaryRow(
      type: 'TAKEAWAY',
      count: settled.where((o) {
        final t = (o.orderType ?? '').toLowerCase();
        return t.isEmpty || t == 'take_away';
      }).length,
      discount: _sumOrders(
        settled.where((o) {
          final t = (o.orderType ?? '').toLowerCase();
          return t.isEmpty || t == 'take_away';
        }),
        (o) => effectiveOrderDiscount(o) + lineDiscountForOrder(o),
      ),
      amount: takeAwaySale,
    ),
  ];

  final paymentVariances = computeSystemPaymentVariances(
    cashExpected: cashSale,
    cardExpected: cardSale,
    creditExpected: creditSale,
    onlineExpected: onlineSale,
    netTotal: netTotal,
  );
  final excessAmount =
      paymentVariances.fold<double>(0, (s, v) => s + v.excess);
  final shortAmount =
      paymentVariances.fold<double>(0, (s, v) => s + v.short);

  final categoryMap = <String, DayClosingCategoryRow>{};
  if (settled.isNotEmpty) {
    final itemByAny = {
      for (final i in visibleItems) i.id: i,
      ...missingItemsById,
    };
    for (final order in settled) {
      final lines = linesByOrderId[order.id] ?? const <CartItem>[];
      for (final line in lines) {
        final item = itemByAny[line.itemId];
        final category = _categoryLabelForLine(line, item, categoryNameByCatId);
        final existingCat = categoryMap[category];
        if (existingCat == null) {
          categoryMap[category] = DayClosingCategoryRow(
            category: category,
            qty: line.quantity,
            amount: line.total,
          );
        } else {
          categoryMap[category] = DayClosingCategoryRow(
            category: existingCat.category,
            qty: existingCat.qty + line.quantity,
            amount: existingCat.amount + line.total,
          );
        }
      }
    }
  }
  final categoryRows = categoryMap.values.toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final userById = {for (final u in users) u.id: u.name};
  final cancelledRows = cancelled
      .map(
        (o) => DayClosingCancelledRow(
          receiptId: o.invoiceNumber,
          reason: (o.referenceNumber ?? '').trim().isEmpty
              ? '—'
              : o.referenceNumber!.trim(),
          by: o.userId == null ? '—' : (userById[o.userId!] ?? 'User ${o.userId}'),
          amount: o.finalAmount,
        ),
      )
      .toList();

  final openBills = unpaidVisible
      .map(
        (o) => DayClosingOpenBill(
          invoiceNumber: o.invoiceNumber,
          status: o.status,
          orderType: o.orderType,
          customerName: o.customerName?.trim(),
          balanceDue: orderBalanceDue(o),
          createdAt: o.createdAt,
        ),
      )
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return DayClosingSummary(
    generatedAt: DateTime.now(),
    // Show the most recent successful day-closing checkpoint timestamp.
    lastClosingAt: cutoff,
    grossTotal: grossTotal,
    totalVatAmount: totalVatAmount,
    discount: discount,
    netTotal: netTotal,
    openingCash: openingCash,
    defaultOpeningCash: defaultOpeningCash,
    cashSaleAfterDiscount: cashSaleAfterDiscount,
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
    unsettledFromAccessibleLogs: unsettledFromAccessibleLogs,
    outstandingCredit: outstandingCredit,
    difference: difference,
    excessAmount: excessAmount,
    shortAmount: shortAmount,
    paymentVariances: paymentVariances,
    typeRows: typeRows,
    categoryRows: categoryRows,
    cancelledRows: cancelledRows,
    openBills: openBills,
    otherIncomeRows: otherIncomeRows,
  );
}

// ── public async entry point ─────────────────────────────────────────────────

/// Computes the same aggregates previously inlined in [DayClosingScreen._load].
///
/// DB queries run on the UI isolate (SQLite cannot cross isolate boundaries).
/// All CPU-bound aggregation is offloaded to a background isolate via [compute].
///
/// [counterAccess] scopes **displayed** unsettled totals and [openBills] to logs
/// the user may open.
/// [scopedCashierUserId] limits sales/unpaid rows to one cashier (SUB tablets);
/// MAIN passes `null`.
Future<DayClosingSummary> computeDayClosingSummary(
  AppDatabase db, {
  CounterAccess counterAccess = const CounterAccess.admin(),
  int? scopedCashierUserId,
}) async {
  final session = await db.sessionDao.getActiveSession();
  final branchId = session?.branchId ?? 1;
  final rawOrders = _ordersForCashierScope(
    await db.ordersDao.getAllOrders(branchId: branchId),
    scopedCashierUserId,
  );
  final cutoff =
      await db.dayClosingCheckpointDao.lastSettledAtForBranch(branchId);
  final branch = await db.branchesDao.getBranchById(branchId);
  final users = await db.usersDao.getAllUsers();
  final visibleItems = await db.itemDao.getVisibleForBranch(branchId);
  final branchCategories = await db.categoryDao.getVisibleForBranch(branchId);
  final categoryNameByCatId = {
    for (final c in branchCategories) c.id: (c.name).trim(),
  };

  // Fetch cart lines for settled orders (DB work must stay on the main isolate).
  final ordersInWindow = cutoff == null
      ? rawOrders
      : rawOrders.where((o) => orderInDayCloseWindow(o, cutoff)).toList();
  final settledAllIds =
      ordersInWindow.where(_isSettledForDayClose).toList();
  final settled =
      settledAllIds.where((o) => orderCreatedInDayCloseWindow(o, cutoff)).toList();

  final linesByOrderId = <int, List<CartItem>>{};
  if (settled.isNotEmpty) {
    const parallel = 24;
    for (var i = 0; i < settled.length; i += parallel) {
      final end = i + parallel > settled.length ? settled.length : i + parallel;
      final slice = settled.sublist(i, end);
      final batch = await Future.wait(
        slice.map((o) => OrderLogCartFallback.resolveWithDb(order: o, db: db)),
      );
      for (var j = 0; j < slice.length; j++) {
        linesByOrderId[slice[j].id] = batch[j];
      }
    }
  }

  // Fetch any items missing from the visible set (archived/hidden items still on old orders).
  final settledItemIds = <int>{};
  for (final lines in linesByOrderId.values) {
    for (final l in lines) {
      settledItemIds.add(l.itemId);
    }
  }
  final visibleById = {for (final i in visibleItems) i.id: i};
  final missingIds =
      settledItemIds.difference(visibleById.keys.toSet()).toList();
  final missingItemsById = <int, Item>{};
  if (missingIds.isNotEmpty) {
    final extras =
        await (db.select(db.items)..where((i) => i.id.isIn(missingIds))).get();
    for (final e in extras) {
      missingItemsById[e.id] = e;
    }
  }

  final purchase = await db.financialRecordsDao.sumFinalAmount(
    branchId: branchId,
    recordType: FinancialRecordType.expense.storageKey,
    lastSettledAt: cutoff,
  );
  final salary = await db.financialRecordsDao.sumFinalAmount(
    branchId: branchId,
    recordType: FinancialRecordType.salary.storageKey,
    lastSettledAt: cutoff,
  );
  final otherIncomeRecords = await db.financialRecordsDao.listSinceClose(
    branchId: branchId,
    recordType: FinancialRecordType.otherIncome.storageKey,
    lastSettledAt: cutoff,
  );
  final otherIncomeRows = otherIncomeRecords
      .map(
        (r) => DayClosingOtherIncomeRow(
          description: (r.description ?? '').trim().isEmpty ? '—' : r.description!.trim(),
          payment: (r.paymentMethodName ?? '—').trim(),
          amount: r.finalAmount,
          createdAt: r.createdAt,
        ),
      )
      .toList();

  // Offload all aggregation to a background isolate.
  return compute(
    _computeSummarySync,
    _DayClosingComputeInput(
      rawOrders: rawOrders,
      cutoff: cutoff,
      branch: branch,
      users: users,
      visibleItems: visibleItems,
      categoryNameByCatId: categoryNameByCatId,
      linesByOrderId: linesByOrderId,
      counterAccess: counterAccess,
      missingItemsById: missingItemsById,
      purchase: purchase,
      salary: salary,
      otherIncomeRows: otherIncomeRows,
    ),
  );
}
