import 'package:pos/data/local/drift_database.dart';

abstract class CartRepository {
  Future<int> createCart(
    String invoiceNumber, {
    String? orderType,
    String? deliveryPartner,
    int branchId = 1,
  });

  Future<void> deleteCart(int cartId);

  /// Removes `_draft-*` carts that were never linked to an order (counter refresh / back navigation).
  Future<void> deleteOrphanDraftCarts();

  Future<List<Cart>> getAllCarts();

  Future<Cart?> getCartByInvoice(String invoiceNumber);
  Future<Cart?> getCartByCartId(int cartId);

  /// Keeps cart row in sync when an order changes service type (move between logs).
  Future<void> updateCartOrderInfo(int cartId, {required String orderType, String? deliveryPartner});
  Future<void> updateCartInvoiceNumber(int cartId, String invoiceNumber);

  Future<List<CartItem>?> getCartItemsByCartId(int cartId);

  /// Cart id → number of line items (single round-trip for many carts).
  Future<Map<int, int>> countCartItemsByCartIds(List<int> cartIds);

  /// Reassign lines to another cart (split / merge).
  Future<void> reassignCartItemsToCart(List<int> cartItemIds, int targetCartId);

  Future<int> addItemToCart(int cartId, CartItem item);

  Future<void> updateCartItem(CartItem item);

  Future<void> updateCartItemTotal(int cartItemId, double total);

  Future<void> removeCartItem(int cartItemId);

  /// Clears and re-inserts all lines (single transaction).
  Future<void> replaceCartItems(int cartId, List<CartItem> lines);
}
