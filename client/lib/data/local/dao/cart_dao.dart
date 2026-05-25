part of '../drift_database.dart';

class Carts extends Table {
  IntColumn get id => integer()();
  TextColumn get invoiceNumber => text()();
  DateTimeColumn get createdAt => dateTime()();
  /// 'take_away' | 'delivery' | 'dine_in'
  TextColumn get orderType => text().withDefault(const Constant('take_away'))();
  /// Delivery partner name (Swiggy, Zomato, etc.) when orderType is 'delivery'
  TextColumn get deliveryPartner => text().nullable()();

  /// Matches [Orders.branchId] once the sale is finalized; used for invoice suffix scoping.
  IntColumn get branchId => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

class CartItems extends Table {
  IntColumn get id => integer()();

  IntColumn get cartId => integer().references(Carts, #id)();

  IntColumn get itemId => integer().references(Items, #id)();

  /// Snapshot of catalog name at time of sale (KOT, offline display; survives item rename).
  TextColumn get itemName => text().withDefault(const Constant(''))();

  IntColumn get itemVariantId => integer().nullable().references(ItemVariants, #id)();

  IntColumn get itemToppingId => integer().nullable().references(ItemToppings, #id)();

  IntColumn get quantity => integer()();
  RealColumn get total => real().withDefault(const Constant(0))();

  RealColumn get discount => real().withDefault(const Constant(0))();

  TextColumn get discountType => text().nullable()(); // 'amount' or 'percentage'

  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [
  Carts,
  CartItems,
  Items,
  ItemVariants,
  ItemToppings,
])
class CartsDao extends DatabaseAccessor<AppDatabase> with _$CartsDaoMixin {
  CartsDao(super.db);

  /* ───────── CART ───────── */

  Future<int> createCart(
    String invoiceNumber, {
    String? orderType,
    String? deliveryPartner,
    int branchId = 1,
  }) {
    return into(carts).insert(
      CartsCompanion.insert(
        invoiceNumber: invoiceNumber,
        createdAt: DateTime.now(),
        orderType: orderType != null ? Value(orderType) : const Value.absent(),
        deliveryPartner: deliveryPartner != null ? Value(deliveryPartner) : const Value.absent(),
        branchId: Value(branchId),
      ),
    );
  }

  Future<void> deleteCart(int cartId) async {
    await (delete(cartItems)..where((c) => c.cartId.equals(cartId))).go();

    await (delete(carts)..where((c) => c.id.equals(cartId))).go();
  }

  Future<Cart?> getCartByInvoice(String invoice) {
    return (select(carts)..where((c) => c.invoiceNumber.equals(invoice))).getSingleOrNull();
  }

  Future<Cart?> getCartByCartId(int cartId) {
    return (select(carts)..where((c) => c.id.equals(cartId))).getSingleOrNull();
  }

  Future<void> updateCartOrderInfo(int cartId, {required String orderType, String? deliveryPartner}) {
    return (update(carts)..where((c) => c.id.equals(cartId))).write(
      CartsCompanion(
        orderType: Value(orderType),
        deliveryPartner: Value(deliveryPartner),
      ),
    );
  }

  /* ───────── CART ITEMS ───────── */

  Future<int> addCartItem(CartItemsCompanion data) {
    return into(cartItems).insert(data);
  }

  Future<void> updateCartItem(CartItemsCompanion data) {
    return into(cartItems).insertOnConflictUpdate(data);
  }

  /// Explicit UPDATE for total (used when unit price is edited).
  Future<void> updateCartItemTotal(int cartItemId, double total) {
    return (update(cartItems)..where((c) => c.id.equals(cartItemId)))
        .write(CartItemsCompanion(total: Value(total)));
  }

  Future<void> removeCartItem(int id) {
    return (delete(cartItems)..where((c) => c.id.equals(id))).go();
  }

  /// Move existing lines to another cart (split / merge bills).
  Future<void> reassignCartItemsToCart(List<int> cartItemIds, int targetCartId) async {
    if (cartItemIds.isEmpty) return;
    await (update(cartItems)..where((c) => c.id.isIn(cartItemIds)))
        .write(CartItemsCompanion(cartId: Value(targetCartId)));
  }

  Future<List<CartItem>> getItemsByCart(int cartId) {
    return (select(cartItems)
          ..where((c) => c.cartId.equals(cartId))
          ..orderBy([(c) => OrderingTerm.desc(c.id)]))
        .get();
  }

  /// One query: line counts per cart (for order log cards, split visibility).
  Future<Map<int, int>> countCartItemsByCartIds(List<int> cartIds) async {
    if (cartIds.isEmpty) return {};
    final map = {for (final id in cartIds) id: 0};
    final rows = await (select(cartItems)..where((c) => c.cartId.isIn(cartIds))).get();
    for (final row in rows) {
      map[row.cartId] = (map[row.cartId] ?? 0) + 1;
    }
    return map;
  }

  /// Highest numeric suffix for cart invoices in [branchId] and [prefix].
  ///
  /// Supports:
  /// - Current format: `PREFIX-branchId-###` (e.g. `INV-1-002`)
  /// - Legacy format: `PREFIX##` (e.g. `INV02`)
  Future<int> maxInvoiceNumericSuffixForPrefix(String prefix, {required int branchId}) async {
    // Invoice number only — avoids deserializing created_at (bad TEXT seeds crash Drift).
    final rows = await (selectOnly(carts)
          ..addColumns([carts.invoiceNumber])
          ..where(carts.invoiceNumber.like('$prefix%'))
          ..where(carts.branchId.equals(branchId)))
        .get();
    var max = 0;
    final escapedPrefix = RegExp.escape(prefix);
    final currentFormat = RegExp('^$escapedPrefix-$branchId-(\\d+)\$');
    final legacyFormat = RegExp('^$escapedPrefix(\\d+)\$');

    for (final row in rows) {
      final inv = row.read(carts.invoiceNumber)!;
      int? v;
      final currentMatch = currentFormat.firstMatch(inv);
      if (currentMatch != null) {
        v = int.tryParse(currentMatch.group(1)!);
      } else {
        final legacyMatch = legacyFormat.firstMatch(inv);
        if (legacyMatch != null) {
          v = int.tryParse(legacyMatch.group(1)!);
        }
      }
      if (v != null && v > max) max = v;
    }
    return max;
  }
}
