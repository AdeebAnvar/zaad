import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/order_payment_utils.dart';
import 'package:pos/data/local/drift_database.dart';

Order _order({
  required String status,
  double finalAmount = 100,
  double cash = 0,
}) {
  return Order(
    id: 1,
    cartId: 1,
    invoiceNumber: 'INV-1',
    totalAmount: finalAmount,
    discountAmount: 0,
    finalAmount: finalAmount,
    status: status,
    orderType: 'delivery',
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
  test('orderCountsAsRecentSale includes fully paid pending delivery', () {
    expect(
      orderCountsAsRecentSale(_order(status: 'pending', cash: 100)),
      isTrue,
    );
  });

  test('orderCountsAsRecentSale excludes unpaid pending delivery', () {
    expect(
      orderCountsAsRecentSale(_order(status: 'pending', cash: 0)),
      isFalse,
    );
  });

  test('orderCountsAsRecentSale includes completed', () {
    expect(
      orderCountsAsRecentSale(_order(status: 'completed', cash: 0)),
      isTrue,
    );
  });

  test('orderCountsAsRecentSale excludes kot', () {
    expect(
      orderCountsAsRecentSale(_order(status: 'kot', cash: 100)),
      isFalse,
    );
  });
}
