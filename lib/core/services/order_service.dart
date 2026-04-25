import 'dart:convert';

import 'package:pos/data/local/drift_database.dart';

class OrderService {
  OrderService(this._db);

  final AppDatabase _db;

  /// Transaction-safe save for order header + existing order items snapshot log.
  Future<int> createOrderWithSnapshot({
    required OrdersCompanion order,
    required List<CartItem> orderItems,
  }) async {
    late final int orderId;
    await _db.transaction(() async {
      orderId = await _db.ordersDao.createOrder(order);
      final payload = {
        'order_id': orderId,
        'created_at': DateTime.now().toIso8601String(),
        'items': orderItems
            .map(
              (item) => {
                'id': item.id,
                'cart_id': item.cartId,
                'item_id': item.itemId,
                'item_variant_id': item.itemVariantId,
                'item_topping_id': item.itemToppingId,
                'quantity': item.quantity,
                'total': item.total,
                'discount': item.discount,
                'discount_type': item.discountType,
                'notes': item.notes,
              },
            )
            .toList(),
      };
      await _db.ordersDao.insertOrderLog(jsonEncode(payload));
    });
    return orderId;
  }
}

