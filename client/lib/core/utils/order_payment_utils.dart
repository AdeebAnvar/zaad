import 'package:pos/data/local/drift_database.dart';

/// Bill total used for pay / balance checks ([Order.finalAmount] or [Order.totalAmount]).
double orderPayableAmount(Order o) =>
    o.finalAmount > 0.009 ? o.finalAmount : o.totalAmount;

double orderPaidAmount(Order o) =>
    o.cashAmount + o.cardAmount + o.creditAmount + o.onlineAmount;

/// True when the order still owes money (matches dine-in / delivery log pay rules).
bool orderHasOutstandingBalance(Order o, {double tolerance = 0.02}) {
  final payable = orderPayableAmount(o);
  if (payable <= 0.009) return false;
  return orderPaidAmount(o) + tolerance < payable;
}

/// Remaining amount to collect (0 when fully paid).
double orderBalanceDue(Order o) {
  final due = orderPayableAmount(o) - orderPaidAmount(o);
  return due > 0.009 ? due : 0.0;
}
