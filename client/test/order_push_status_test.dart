import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/orders/data/order_push_status.dart';

void main() {
  test('toRemote: completed takeaway maps to delivered on hub', () {
    expect(
      OrderPushStatus.toRemote(orderType: 'take_away', localStatus: 'completed'),
      'delivered',
    );
  });

  test('localFromHub: delivered takeaway maps back to completed', () {
    expect(
      OrderPushStatus.localFromHub(orderType: 'take_away', hubStatus: 'delivered'),
      'completed',
    );
  });

  test('toRemote: open kot takeaway stays pending on hub', () {
    expect(
      OrderPushStatus.toRemote(orderType: 'take_away', localStatus: 'kot'),
      'pending',
    );
  });
}
