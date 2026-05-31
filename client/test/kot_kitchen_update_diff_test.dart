import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/print/kot_kitchen_update_diff.dart';
import 'package:pos/data/local/drift_database.dart';

void main() {
  test('compute reports only new lines and qty increases', () {
    final tea = CartItem(
      id: 1,
      cartId: 10,
      itemId: 100,
      itemName: 'Tea',
      quantity: 1,
      discount: 0,
      total: 5,
    );
    final coffee = CartItem(
      id: 2,
      cartId: 10,
      itemId: 101,
      itemName: 'Coffee',
      quantity: 1,
      discount: 0,
      total: 8,
    );
    final rows = KotKitchenUpdateDiff.compute(
      [tea],
      [tea, coffee],
    );
    expect(rows, hasLength(1));
    expect(rows.single.lineForKitchen.itemName, 'Coffee');
    expect(rows.single.isCancelled, isFalse);
  });

  test('compute reports qty decrease as cancelled delta', () {
    final baseline = CartItem(
      id: 1,
      cartId: 10,
      itemId: 100,
      itemName: 'Tea',
      quantity: 2,
      discount: 0,
      total: 10,
    );
    final current = baseline.copyWith(quantity: 1, total: 5);
    final rows = KotKitchenUpdateDiff.compute([baseline], [current]);
    expect(rows, hasLength(1));
    expect(rows.single.isCancelled, isTrue);
    expect(rows.single.lineForKitchen.quantity, 1);
  });
}
