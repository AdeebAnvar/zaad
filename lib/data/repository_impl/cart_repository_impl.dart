import 'package:drift/drift.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  final AppDatabase db;

  CartRepositoryImpl(this.db);

  /* ───────── CART ───────── */

  @override
  Future<int> createCart(String invoiceNumber, {String? orderType, String? deliveryPartner}) {
    return db.cartsDao.createCart(invoiceNumber, orderType: orderType, deliveryPartner: deliveryPartner);
  }

  @override
  Future<void> deleteCart(int cartId) {
    return db.cartsDao.deleteCart(cartId);
  }

  @override
  Future<Cart?> getCartByInvoice(String invoice) async {
    return db.cartsDao.getCartByInvoice(invoice);
  }

  @override
  Future<List<Cart>> getAllCarts() async {
    return db.cartsDao.select(db.cartsDao.carts).get();
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
    return db.cartsDao.getCartByCartId(cartId);
  }
}
