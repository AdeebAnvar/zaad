import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/delivery_log/delivery_log_cubit.dart';

Order _deliveryOrder({
  required String status,
  double totalAmount = 100,
  double finalAmount = 100,
  double cash = 0,
  double card = 0,
  double credit = 0,
  double online = 0,
}) {
  return Order(
    id: 1,
    cartId: 1,
    invoiceNumber: 'INV-1',
    totalAmount: totalAmount,
    discountAmount: 0,
    finalAmount: finalAmount,
    status: status,
    orderType: 'delivery',
    createdAt: DateTime(2026, 1, 1),
    cashAmount: cash,
    cardAmount: card,
    creditAmount: credit,
    onlineAmount: online,
    branchId: 1,
    hubSyncPending: false,
  );
}

void main() {
  test('deliveryLogOrderVisible keeps unpaid pending delivery', () {
    expect(
      deliveryLogOrderVisible(_deliveryOrder(status: 'pending')),
      isTrue,
    );
  });

  test('deliveryLogOrderVisible keeps fully paid pending delivery', () {
    expect(
      deliveryLogOrderVisible(
        _deliveryOrder(status: 'pending', cash: 100),
      ),
      isTrue,
    );
  });

  test('deliveryLogOrderVisible hides completed even if underpaid', () {
    expect(
      deliveryLogOrderVisible(
        _deliveryOrder(status: 'completed', cash: 0),
      ),
      isFalse,
    );
  });

  test('deliveryLogOrderVisible keeps partial payment', () {
    expect(
      deliveryLogOrderVisible(
        _deliveryOrder(status: 'kot', cash: 40),
      ),
      isTrue,
    );
  });

  test('deliveryLogShowPayAction hides pay for pending phase', () {
    expect(deliveryLogShowPayAction(_deliveryOrder(status: 'pending')), isFalse);
    expect(deliveryLogShowPayAction(_deliveryOrder(status: 'placed')), isFalse);
    expect(deliveryLogShowPayAction(_deliveryOrder(status: 'kot')), isFalse);
  });

  test('deliveryLogShowPayAction allows pay after dispatch status', () {
    expect(deliveryLogShowPayAction(_deliveryOrder(status: 'dispatched')), isTrue);
    expect(deliveryLogShowPayAction(_deliveryOrder(status: 'out_of_delivery')), isTrue);
  });
}
