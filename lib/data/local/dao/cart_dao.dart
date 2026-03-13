part of '../drift_database.dart';

class Carts extends Table {
  IntColumn get id => integer()();
  TextColumn get invoiceNumber => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CartItems extends Table {
  IntColumn get id => integer()();

  IntColumn get cartId => integer().references(Carts, #id)();

  IntColumn get itemId => integer().references(Items, #id)();

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
  CartsDao(AppDatabase db) : super(db);

  /* ───────── CART ───────── */

  Future<int> createCart(String invoiceNumber) {
    return into(carts).insert(
      CartsCompanion.insert(
        invoiceNumber: invoiceNumber,
        createdAt: DateTime.now(),
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

  Future<List<CartItem>> getItemsByCart(int cartId) {
    return (select(cartItems)
          ..where((c) => c.cartId.equals(cartId))
          ..orderBy([(c) => OrderingTerm.desc(c.id)]))
        .get();
  }
}
