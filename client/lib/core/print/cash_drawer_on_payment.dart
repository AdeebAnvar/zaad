import 'package:get_it/get_it.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/debug/agent_debug_log.dart';
import 'package:pos/core/print/print_service.dart';

/// Cash tender from payment dialog map, falling back to saved order row.
double resolveCashTenderForDrawer(Map<String, double> payments, {double orderCashAmount = 0}) {
  final fromPayments = payments['cash'] ?? 0.0;
  if (fromPayments > 0.004) return fromPayments;
  return orderCashAmount;
}

/// Pulse the cash drawer after a cash tender.
///
/// Not gated on Invoice/KOT print checkboxes. Not gated on [CounterAccess.canOpenDrawer]
/// (that permission is for the manual drawer menu + password). Any cashier completing
/// a cash sale should trigger the drawer pulse when hardware is configured.
Future<List<String>> openCashDrawerForCashPayment(double cashAmount) async {
  if (cashAmount <= 0.004) {
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H-drawer-skip',
      location: 'cash_drawer_on_payment.dart',
      message: 'cash_drawer_skipped_zero_cash',
      data: <String, Object?>{'cashAmount': cashAmount},
    );
    // #endregion
    return const [];
  }
  try {
    if (!GetIt.instance.isRegistered<PrintService>()) {
      return const ['Cash drawer (print service unavailable)'];
    }
    final failed = await GetIt.instance<PrintService>().openCashDrawer();
    final canOpenDrawer = GetIt.instance.isRegistered<CurrentCounterSession>()
        ? GetIt.instance<CurrentCounterSession>().access.canOpenDrawer
        : null;
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H-drawer-pay',
      location: 'cash_drawer_on_payment.dart',
      message: failed.isEmpty ? 'cash_drawer_payment_ok' : 'cash_drawer_payment_failed',
      data: <String, Object?>{
        'cashAmount': cashAmount,
        'canOpenDrawerPermission': canOpenDrawer,
        'failedLabels': failed,
      },
    );
    // #endregion
    return failed;
  } catch (e) {
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H-drawer-pay',
      location: 'cash_drawer_on_payment.dart',
      message: 'cash_drawer_payment_exception',
      data: <String, Object?>{'cashAmount': cashAmount, 'error': e.toString()},
    );
    // #endregion
    return const ['Cash drawer (bill printer)'];
  }
}
