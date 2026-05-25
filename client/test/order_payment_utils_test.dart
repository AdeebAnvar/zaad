import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/order_payment_utils.dart';
import 'package:pos/data/local/drift_database.dart';

Order _order({
  double totalAmount = 100,
  double finalAmount = 100,
  double cash = 0,
  String status = 'pending',
}) {
  return Order(
    id: 1,
    cartId: 1,
    invoiceNumber: 'INV-1',
    totalAmount: totalAmount,
    discountAmount: 0,
    finalAmount: finalAmount,
    status: status,
    createdAt: DateTime(2026, 1, 1),
    cashAmount: cash,
    cardAmount: 0,
    creditAmount: 0,
    onlineAmount: 0,
    branchId: 1,
    hubSyncPending: false,
  );
}

void main() {
  test('orderBalanceDue returns remaining payable', () {
    expect(orderBalanceDue(_order(cash: 98)), closeTo(2, 0.01));
    expect(orderBalanceDue(_order(cash: 100)), 0);
  });

  test('orderPayableAmount falls back to totalAmount when final is zero', () {
    expect(orderPayableAmount(_order(finalAmount: 0, totalAmount: 2)), closeTo(2, 0.01));
    expect(orderHasOutstandingBalance(_order(finalAmount: 0, totalAmount: 2)), isTrue);
  });
}
