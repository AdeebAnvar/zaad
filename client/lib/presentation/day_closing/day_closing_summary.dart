import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/data/local/drift_database.dart';

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

/// Completed / cancelled excluded; dine-in `kot` excluded (kitchen-only).
bool _isUnsettledForDayClose(Order o) {
  final s = o.status.toLowerCase();
  if (s == 'completed' || s == 'cancelled') return false;
  if (s == 'kot') {
    final t = (o.orderType ?? '').trim().toLowerCase();
    return t != 'dine_in';
  }
  return true;
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

/// Shared aggregates for day closing UI and `settle_sales` push payload.
class DayClosingSummary {
  final DateTime generatedAt;
  final DateTime? lastClosingAt;
  final double grossTotal;
  final double totalVatAmount;
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
  final List<DayClosingTypeSummaryRow> typeRows;
  final List<DayClosingCategoryRow> categoryRows;
  final List<DayClosingCancelledRow> cancelledRows;
  /// Open bills the user may review (same log permissions as [unsettledFromAccessibleLogs]).
  final List<DayClosingOpenBill> openBills;

  const DayClosingSummary({
    required this.generatedAt,
    required this.lastClosingAt,
    required this.grossTotal,
    required this.totalVatAmount,
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
    required this.unsettledFromAccessibleLogs,
    required this.outstandingCredit,
    required this.difference,
    required this.excessAmount,
    required this.shortAmount,
    required this.typeRows,
    required this.categoryRows,
    required this.cancelledRows,
    required this.openBills,
  });

  factory DayClosingSummary.empty() => DayClosingSummary(
        generatedAt: DateTime.now(),
        lastClosingAt: null,
        grossTotal: 0,
        totalVatAmount: 0,
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
        unsettledFromAccessibleLogs: 0,
        outstandingCredit: 0,
        difference: 0,
        excessAmount: 0,
        shortAmount: 0,
        typeRows: const [],
        categoryRows: const [],
        cancelledRows: const [],
        openBills: const [],
      );
}

class DayClosingOpenBill {
  final String invoiceNumber;
  final String status;
  final String? orderType;
  final double finalAmount;
  final DateTime createdAt;

  const DayClosingOpenBill({
    required this.invoiceNumber,
    required this.status,
    required this.orderType,
    required this.finalAmount,
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

/// Computes the same aggregates previously inlined in [DayClosingScreen._load].
///
/// [counterAccess] scopes **displayed** unsettled totals and [openBills] to logs the user may open.
/// Branch-wide [unpaidAmount] and reconciliation stay full-branch for correctness and submit.
Future<DayClosingSummary> computeDayClosingSummary(
  AppDatabase db, {
  CounterAccess counterAccess = const CounterAccess.admin(),
}) async {
  final session = await db.sessionDao.getActiveSession();
  final branchId = session?.branchId ?? 1;
  final rawOrders = await db.ordersDao.getAllOrders(branchId: branchId);
  final cutoff = await db.dayClosingCheckpointDao.lastSettledAtForBranch(branchId);
  /// Sales/cancel rows after last successful close (reset “today” without re-counting settled history).
  final ordersInWindow = cutoff == null
      ? rawOrders
      : rawOrders.where((o) => o.createdAt.isAfter(cutoff)).toList();
  final branch = await db.branchesDao.getBranchById(branchId);
  final users = await db.usersDao.getAllUsers();
  final visibleItems = await db.itemDao.getVisibleForBranch(branchId);
  final branchCategories = await db.categoryDao.getVisibleForBranch(branchId);
  final categoryNameByCatId = {
    for (final c in branchCategories) c.id: (c.name).trim(),
  };

  final settled = ordersInWindow.where(_isSettledForDayClose).toList();
  /// Ignore checkpoint — show all cancelled rows still stored locally (same branch).
  final cancelled =
      rawOrders.where((o) => o.status.toLowerCase() == 'cancelled').toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  /// Ignore checkpoint — see comment on [computeDayClosingSummary].
  final unpaidBranchList = rawOrders.where(_isUnsettledForDayClose).toList();
  final unpaidVisible =
      unpaidBranchList.where((o) => _unsettledMatchesUserLogAccess(o, counterAccess)).toList();
  final linesByCartId = <int, List<CartItem>>{};
  final cartLineDiscountByCartId = <int, double>{};
  if (settled.isNotEmpty) {
    final cartIds = settled.map((o) => o.cartId).toSet().toList();
    // Chunked parallel reads — faster than strictly sequential awaits on large histories.
    const parallel = 48;
    for (var i = 0; i < cartIds.length; i += parallel) {
      final end = i + parallel > cartIds.length ? cartIds.length : i + parallel;
      final slice = cartIds.sublist(i, end);
      final batch = await Future.wait(
        slice.map((cid) => db.cartsDao.getItemsByCart(cid)),
      );
      for (var j = 0; j < slice.length; j++) {
        linesByCartId[slice[j]] = batch[j];
      }
    }
    for (final entry in linesByCartId.entries) {
      final lineDiscount = entry.value.fold<double>(0, (s, l) => s + l.discount);
      cartLineDiscountByCartId[entry.key] = lineDiscount;
    }
  }
  double effectiveOrderDiscount(Order o) =>
      (_orderLevelDiscount(o) + (cartLineDiscountByCartId[o.cartId] ?? 0.0))
          .clamp(0, o.totalAmount);
  double effectiveOrderNet(Order o) =>
      (o.totalAmount - effectiveOrderDiscount(o)).clamp(0.0, o.totalAmount).toDouble();

  final discount = _sumOrders(settled, effectiveOrderDiscount);
  final netTotal = _sumOrders(settled, effectiveOrderNet);
  // Keep gross aligned with billing view: amount before discount = net + discount.
  final grossTotal = netTotal + discount;
  final vatMode = (branch?.vat ?? '').trim().toLowerCase();
  final vp = branch?.vatPercent;
  final vatPct = vp is num ? vp.toDouble() : double.tryParse('$vp') ?? 0.0;
  final totalVatAmount = (vatMode.isNotEmpty && vatMode != 'no_vat' && vatPct > 0)
      ? (netTotal - (netTotal / (1 + vatPct / 100.0)))
      : 0.0;
  final cashSale = _sumOrders(settled, (o) => o.cashAmount);
  final cashSaleAfterDiscount = _cashSaleAfterDiscount(settled, effectiveOrderDiscount);
  final cardSale = _sumOrders(settled, (o) => o.cardAmount);
  final creditSale = _sumOrders(settled, (o) => o.creditAmount);
  final onlineSale = _sumOrders(settled, (o) => o.onlineAmount);

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
  final unpaidAmount = _sumOrders(unpaidBranchList, (o) => o.finalAmount);
  final unsettledFromAccessibleLogs =
      _sumOrders(unpaidVisible, (o) => o.finalAmount);
  final outstandingCredit = _sumOrders(unpaidBranchList, (o) => o.creditAmount);

  final openingCash = (branch?.openingCash ?? 0).toDouble();
  const creditRecovery = 0.0;
  const deliveryRecovery = 0.0;
  const purchase = 0.0;
  const salary = 0.0;
  const otherIncome = 0.0;
  final expUnpaidTotal = purchase + salary + unpaidAmount - otherIncome;
  // Modeled drawer per requirement:
  // opening cash + cash sales (after discount) - expenses paid from cash.
  final cashIn = openingCash + cashSaleAfterDiscount;
  final cashOut = purchase + salary;
  final cashDrawer = cashIn - cashOut;
  final difference = expUnpaidTotal - cashDrawer;

  final typeRows = <DayClosingTypeSummaryRow>[
    DayClosingTypeSummaryRow(
      type: 'DINE-IN',
      count: settled.where((o) => (o.orderType ?? '').toLowerCase() == 'dine_in').length,
      discount: _sumOrders(
        settled.where((o) => (o.orderType ?? '').toLowerCase() == 'dine_in'),
        effectiveOrderDiscount,
      ),
      amount: dineInSales,
    ),
    DayClosingTypeSummaryRow(
      type: 'DELIVERY',
      count:
          settled.where((o) => (o.orderType ?? '').toLowerCase() == 'delivery').length,
      discount: _sumOrders(
        settled.where((o) => (o.orderType ?? '').toLowerCase() == 'delivery'),
        effectiveOrderDiscount,
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
        effectiveOrderDiscount,
      ),
      amount: takeAwaySale,
    ),
  ];

  final collected = cashSale + cardSale + creditSale + onlineSale;
  final variance = collected - netTotal;
  final excessAmount = variance > 0 ? variance : 0.0;
  final shortAmount = variance < 0 ? -variance : 0.0;

  final categoryMap = <String, DayClosingCategoryRow>{};
  if (settled.isNotEmpty) {
    final settledItemIds = <int>{};
    for (final order in settled) {
      final lines = linesByCartId[order.cartId] ?? const <CartItem>[];
      for (final line in lines) {
        settledItemIds.add(line.itemId);
      }
    }
    final itemByVisible = {for (final i in visibleItems) i.id: i};
    final missingIds = settledItemIds.difference(itemByVisible.keys.toSet()).toList();
    final Map<int, Item> itemByAny = Map<int, Item>.from(itemByVisible);
    if (missingIds.isNotEmpty) {
      final extras =
          await (db.select(db.items)..where((i) => i.id.isIn(missingIds))).get();
      for (final e in extras) {
        itemByAny[e.id] = e;
      }
    }
    for (final order in settled) {
      final lines = linesByCartId[order.cartId] ?? const <CartItem>[];
      for (final line in lines) {
        final item = itemByAny[line.itemId];
        final category = _categoryLabelForLine(line, item, categoryNameByCatId);
        final existing = categoryMap[category];
        if (existing == null) {
          categoryMap[category] = DayClosingCategoryRow(
            category: category,
            qty: line.quantity,
            amount: line.total,
          );
        } else {
          categoryMap[category] = DayClosingCategoryRow(
            category: existing.category,
            qty: existing.qty + line.quantity,
            amount: existing.amount + line.total,
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
          finalAmount: o.finalAmount,
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
    typeRows: typeRows,
    categoryRows: categoryRows,
    cancelledRows: cancelledRows,
    openBills: openBills,
  );
}
