part of 'cart_cubit.dart';

class CartState {
  final List<CartItem> items;
  final bool orderSubmitPending;
  final String? orderSubmitError;

  CartState(
    this.items, {
    this.orderSubmitPending = false,
    this.orderSubmitError,
  });

  int get totalItems => items.fold(0, (sum, e) => sum + e.quantity);

  double get totalAmount => items.fold(0, (sum, e) => sum + e.total);
}
