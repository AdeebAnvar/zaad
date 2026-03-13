import 'package:drift/drift.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  final AppDatabase db;

  CartRepositoryImpl(this.db);

  /* ───────── CART ───────── */

  @override
  Future<int> createCart(String invoiceNumber) {
    return db.cartsDao.createCart(invoiceNumber);
  }

  @override
  Future<void> deleteCart(int cartId) {
    return db.cartsDao.deleteCart(cartId);
  }

  @override
  Future<Cart?> getCartByInvoice(String invoice) async {
    final cart = await db.cartsDao.getCartByInvoice(invoice);
    if (cart == null) return null;

    return Cart(
      id: cart.id,
      invoiceNumber: cart.invoiceNumber,
      createdAt: cart.createdAt,
    );
  }

  @override
  Future<List<Cart>> getAllCarts() async {
    final carts = await db.cartsDao.select(db.cartsDao.carts).get();

    final List<Cart> result = [];

    for (final cart in carts) {
      result.add(
        Cart(
          id: cart.id,
          invoiceNumber: cart.invoiceNumber,
          createdAt: cart.createdAt,
        ),
      );
    }

    return result;
  }

  /* ───────── CART ITEMS ───────── */

  @override
  Future<int> addItemToCart(int cartId, CartItem item) {
    return db.cartsDao.addCartItem(
      CartItemsCompanion.insert(
        cartId: cartId,
        itemId: item.itemId,
        itemVariantId: Value(item.itemVariantId),
        itemToppingId: Value(item.itemToppingId),
        quantity: item.quantity,
        discount: Value(item.discount),
        discountType: Value(item.discountType),
        notes: Value(item.notes),
        total: Value(item.total),
      ),
    );
  }

  @override
  Future<void> updateCartItem(CartItem item) {
    return db.cartsDao.updateCartItem(
      CartItemsCompanion(
        id: Value(item.id),
        cartId: Value(item.cartId),
        itemId: Value(item.itemId),
        itemVariantId: Value(item.itemVariantId),
        itemToppingId: Value(item.itemToppingId),
        quantity: Value(item.quantity),
        discount: Value(item.discount),
        discountType: Value(item.discountType),
        notes: Value(item.notes),
        total: Value(item.total),
      ),
    );
  }

  @override
  Future<void> updateCartItemTotal(int cartItemId, double total) {
    return db.cartsDao.updateCartItemTotal(cartItemId, total);
  }

  @override
  Future<void> removeCartItem(int cartItemId) {
    return db.cartsDao.removeCartItem(cartItemId);
  }

  @override
  Future<List<CartItem>?> getCartItemsByCartId(int cartId) async {
    final items = await db.cartsDao.getItemsByCart(cartId);
    return items;
  }

  @override
  Future<Cart?> getCartByCartId(int cartId) async {
    final cart = await db.cartsDao.getCartByCartId(cartId);
    if (cart == null) return null;

    return Cart(
      id: cart.id,
      invoiceNumber: cart.invoiceNumber,
      createdAt: cart.createdAt,
    );
  }
}
