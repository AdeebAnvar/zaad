part of 'cart_cubit.dart';

class CartState {
  final List<CartItem> items;

  CartState(this.items);

  int get totalItems => items.fold(0, (sum, e) => sum + e.quantity);

  double get totalAmount => items.fold(0, (sum, e) => sum + e.total);
}
