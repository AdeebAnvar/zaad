import 'dart:convert';

import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';

/// SUB → MAIN mirrored orders often have no [`CartItem`] rows (shadow [`Carts`] only).
/// Hydrate display/print dialogs from LAN [`Order.hubMetadata`] or pushed [`OrderLog`] JSON.
class OrderLogCartFallback {
  OrderLogCartFallback._();

  /// Prefer SQLite cart lines; otherwise snapshot `items` / `cart_lines` from hub payload or cloud log.
  static Future<List<CartItem>> resolve({
    required Order order,
    required AppDatabase db,
    required CartRepository cartRepo,
  }) async {
    final fromDb = await cartRepo.getCartItemsByCartId(order.cartId);
    final list = fromDb ?? [];
    if (list.isNotEmpty) return list;

    final hm = order.hubMetadata?.trim();
    if (hm != null && hm.isNotEmpty) {
      final fromHub = decodeCartItemsFromPayloadJson(hm, order.cartId);
      if (fromHub.isNotEmpty) return fromHub;
    }

    final log = await db.ordersDao.findLatestOrderLogByLocalOrderId(order.id);
    if (log != null) {
      try {
        final decoded = jsonDecode(log.orderJson);
        if (decoded is Map<String, dynamic>) {
          final items = decoded['items'];
          if (items is List && items.isNotEmpty) {
            final fromLog = decodeCartItemsFromItemsList(items, order.cartId);
            if (fromLog.isNotEmpty) return fromLog;
          }
        }
      } catch (_) {}
    }
    return [];
  }

  /// Full rows for [OrderLogDetailsDialog]: cart lines from DB or hub snapshot + catalog lookups when possible.
  static Future<List<Map<String, dynamic>>> buildItemsWithDetailsForOrderLog({
    required Order order,
    required AppDatabase db,
    required CartRepository cartRepo,
    required ItemRepository itemRepo,
  }) async {
    final cartItems = await resolve(order: order, db: db, cartRepo: cartRepo);
    final out = <Map<String, dynamic>>[];
    for (final cartItem in cartItems) {
      Item? item;
      if (cartItem.itemId > 0) {
        item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
      }
      ItemVariant? variant;
      final vid = cartItem.itemVariantId;
      if (vid != null && vid > 0) {
        variant = await itemRepo.fetchVariantById(vid);
      }
      ItemTopping? topping;
      final tid = cartItem.itemToppingId;
      if (tid != null && tid > 0) {
        topping = await itemRepo.fetchToppingById(tid);
      }
      out.add(<String, dynamic>{
        'cartItem': cartItem,
        'item': item,
        'variant': variant,
        'topping': topping,
      });
    }
    return out;
  }

  /// Parses LAN envelope wrapper (`snapshot.items`) or flat maps with `items` / `cart_lines`.
  static List<CartItem> decodeCartItemsFromPayloadJson(String jsonStr, int orderCartId) {
    try {
      final root = jsonDecode(jsonStr);
      if (root is! Map<String, dynamic>) return [];

      List<dynamic>? lines;
      final snap = root['snapshot'];
      if (snap is Map<String, dynamic>) {
        final sn = snap['items'];
        if (sn is List && sn.isNotEmpty) lines = sn;
      }

      lines ??= _topLevelItemsOrCartLines(root);

      final metaRaw = root['metadata'];
      if ((lines == null || lines.isEmpty) && metaRaw is Map<String, dynamic>) {
        final cl = metaRaw['cart_lines'];
        if (cl is List && cl.isNotEmpty) lines = cl;
      }
      if ((lines == null || lines.isEmpty) && metaRaw is Map<String, dynamic>) {
        final flutter = metaRaw['flutter'];
        if (flutter is Map<String, dynamic>) {
          final fi = flutter['items'];
          if (fi is List && fi.isNotEmpty) lines = fi;
        }
      }

      if (lines == null || lines.isEmpty) return [];
      return decodeCartItemsFromItemsList(lines, orderCartId);
    } catch (_) {
      return [];
    }
  }

  static List<dynamic>? _topLevelItemsOrCartLines(Map<String, dynamic> root) {
    final items = root['items'];
    if (items is List && items.isNotEmpty) return items;
    final cl = root['cart_lines'];
    if (cl is List && cl.isNotEmpty) return cl;
    return null;
  }

  /// Snapshot line objects from hub / [`OrderLog`] (`item_id`/`item_name` snake_case or camelCase).
  static List<CartItem> decodeCartItemsFromItemsList(List<dynamic> items, int orderCartId) {
    var nid = -1;
    final out = <CartItem>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final line = snapshotLineToCartItem(m, orderCartId, nid--);
      if (line.quantity > 0) out.add(line);
    }
    return out;
  }

  static CartItem snapshotLineToCartItem(Map<String, dynamic> m, int orderCartId, int syntheticId) {
    int readInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    double readDouble(dynamic v, [double fallback = 0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    final qty = readInt(m['quantity'] ?? m['qty'], 1).clamp(1, 999999);
    final id = readInt(m['id'], syntheticId);
    final cartId = readInt(m['cart_id'] ?? m['cartId'], orderCartId);
    final itemId = readInt(m['item_id'] ?? m['itemId'], 0);
    var name = '${m['item_name'] ?? m['itemName'] ?? m['name'] ?? ''}'.trim();
    if (name.isEmpty) name = 'Item';

    final discount = readDouble(m['discount']);
    final discountType = m['discount_type']?.toString() ?? m['discountType']?.toString();
    final notes = m['notes']?.toString();
    final totalRaw = readDouble(m['total']);
    var total = totalRaw;
    if (total <= 0.004) {
      final centsRaw = m['unitPriceCents'] ?? m['unit_price_cents'];
      final cents = centsRaw is num ? centsRaw.round() : int.tryParse('$centsRaw');
      if (cents != null && cents > 0) {
        total = cents * qty / 100.0;
      }
    }

    final varIdRaw = m['item_variant_id'] ?? m['itemVariantId'];
    final topIdRaw = m['item_topping_id'] ?? m['itemToppingId'];

    return CartItem(
      id: id <= 0 ? syntheticId : id,
      cartId: cartId <= 0 ? orderCartId : cartId,
      itemId: itemId,
      itemName: name,
      itemVariantId: varIdRaw == null ? null : readInt(varIdRaw),
      itemToppingId: topIdRaw == null ? null : readInt(topIdRaw),
      quantity: qty,
      total: total,
      discount: discount,
      discountType: discountType,
      notes: notes,
    );
  }
}
