import 'package:pos/data/local/drift_database.dart';

abstract class CartRepository {
  Future<int> createCart(String invoiceNumber);

  Future<void> deleteCart(int cartId);

  Future<List<Cart>> getAllCarts();

  Future<Cart?> getCartByInvoice(String invoiceNumber);
  Future<Cart?> getCartByCartId(int cartId);
  Future<List<CartItem>?> getCartItemsByCartId(int cartId);

  Future<void> addItemToCart(int cartId, CartItem item);

  Future<void> updateCartItem(CartItem item);

  Future<void> removeCartItem(int cartItemId);
}
