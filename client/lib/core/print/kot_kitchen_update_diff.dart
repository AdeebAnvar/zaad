import 'package:pos/data/local/drift_database.dart';

/// One delta line for an "update order" kitchen slip (cancellation or addition).
class KotKitchenUpdateRow {
  const KotKitchenUpdateRow({
    required this.lineForKitchen,
    required this.isCancelled,
  });

  /// Cart line trimmed to [quantity] / [total] reflecting only the delta.
  final CartItem lineForKitchen;

  /// `true` → print `- CANCELLED`; `false` → `- UPDATED`.
  final bool isCancelled;
}

/// Compares cart lines the kitchen already "knows" vs the current cart.
class KotKitchenUpdateDiff {
  KotKitchenUpdateDiff._();

  static double _scaledTotal(CartItem from, int deltaQty) {
    if (deltaQty <= 0) return 0;
    final q = from.quantity;
    if (q <= 0) return 0;
    return from.total * (deltaQty / q);
  }

  /// Kitchen-visible line content (notes, variant, item) — excludes qty/discount/totals.
  static bool kitchenLineContentChanged(CartItem baseline, CartItem current) {
    if (baseline.itemId != current.itemId) return true;
    if (baseline.itemVariantId != current.itemVariantId) return true;
    if ((baseline.notes ?? '').trim() != (current.notes ?? '').trim()) return true;
    return false;
  }

  /// Non-empty deltas only; matched by stable [CartItem.id].
  static List<KotKitchenUpdateRow> compute(List<CartItem> kitchenBaseline, List<CartItem> current) {
    final currentById = {for (final c in current) c.id: c};
    final out = <KotKitchenUpdateRow>[];

    final baseIdsFromBaseline = <int>{};
    for (final b in kitchenBaseline) {
      baseIdsFromBaseline.add(b.id);
      final a = currentById[b.id];

      if (a == null) {
        out.add(KotKitchenUpdateRow(lineForKitchen: b, isCancelled: true));
        continue;
      }

      if (a.quantity < b.quantity) {
        final dq = b.quantity - a.quantity;
        out.add(KotKitchenUpdateRow(
          lineForKitchen: b.copyWith(quantity: dq, total: _scaledTotal(b, dq)),
          isCancelled: true,
        ));
      } else if (a.quantity > b.quantity) {
        final dq = a.quantity - b.quantity;
        out.add(KotKitchenUpdateRow(
          lineForKitchen: a.copyWith(quantity: dq, total: _scaledTotal(a, dq)),
          isCancelled: false,
        ));
      } else if (kitchenLineContentChanged(b, a)) {
        out.add(KotKitchenUpdateRow(
          lineForKitchen: a,
          isCancelled: false,
        ));
      }
    }

    for (final a in current) {
      if (!baseIdsFromBaseline.contains(a.id)) {
        out.add(KotKitchenUpdateRow(lineForKitchen: a, isCancelled: false));
      }
    }

    return out;
  }
}

/// Input for [kotKitchenUpdateDiffInIsolate] ([AppIsolateService] / [flutterCompute]).
class KotKitchenUpdateDiffInput {
  const KotKitchenUpdateDiffInput({
    required this.baseline,
    required this.current,
  });

  final List<CartItem> baseline;
  final List<CartItem> current;
}

@pragma('vm:entry-point')
List<KotKitchenUpdateRow> kotKitchenUpdateDiffInIsolate(KotKitchenUpdateDiffInput input) {
  return KotKitchenUpdateDiff.compute(input.baseline, input.current);
}
