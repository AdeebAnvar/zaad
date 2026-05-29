import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/print/kot_kitchen_update_diff.dart';
import 'package:pos/data/local/drift_database.dart';

CartItem _line({
  required int id,
  int quantity = 1,
  String? notes,
}) {
  return CartItem(
    id: id,
    cartId: 1,
    itemId: 100 + id,
    itemName: 'Item $id',
    quantity: quantity,
    total: 10.0 * quantity,
    discount: 0,
    notes: notes,
  );
}

void main() {
  group('KotKitchenUpdateDiff', () {
    test('emits UPDATED row when line note changes at same quantity', () {
      final baseline = [
        _line(
          id: 1,
          notes: '{"toppings":[],"lineNote":"no onion"}',
        ),
      ];
      final current = [
        _line(
          id: 1,
          notes: '{"toppings":[],"lineNote":"extra spicy"}',
        ),
      ];

      final rows = KotKitchenUpdateDiff.compute(baseline, current);

      expect(rows, hasLength(1));
      expect(rows.single.isCancelled, isFalse);
      expect(rows.single.lineForKitchen.notes, current.single.notes);
      expect(rows.single.lineForKitchen.quantity, 1);
    });

    test('emits UPDATED row when plain-text note changes', () {
      final baseline = [_line(id: 2, notes: 'mild')];
      final current = [_line(id: 2, notes: 'hot')];

      final rows = KotKitchenUpdateDiff.compute(baseline, current);

      expect(rows, hasLength(1));
      expect(rows.single.isCancelled, isFalse);
      expect(rows.single.lineForKitchen.notes, 'hot');
    });

    test('no row when note unchanged at same quantity', () {
      final baseline = [_line(id: 3, notes: 'same')];
      final current = [_line(id: 3, notes: 'same')];

      expect(KotKitchenUpdateDiff.compute(baseline, current), isEmpty);
    });

    test('quantity increase takes precedence over note-only path', () {
      final baseline = [_line(id: 4, quantity: 1, notes: 'a')];
      final current = [_line(id: 4, quantity: 2, notes: 'b')];

      final rows = KotKitchenUpdateDiff.compute(baseline, current);

      expect(rows, hasLength(1));
      expect(rows.single.isCancelled, isFalse);
      expect(rows.single.lineForKitchen.quantity, 1);
      expect(rows.single.lineForKitchen.notes, 'b');
    });
  });
}
