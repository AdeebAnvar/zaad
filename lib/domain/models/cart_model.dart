import 'package:pos/domain/models/cart_item_model.dart';

class CartModel {
  final String invoiceNumber;
  final DateTime createdAt;
  final List<CartItemModel> items;

  CartModel({
    required this.invoiceNumber,
    required this.items,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subTotal => items.fold(0, (sum, e) => sum + e.total);

  double get totalDiscount => items.fold(0, (sum, e) => sum + e.discount);

  double get grandTotal => subTotal - totalDiscount;

  CartModel copyWith({
    String? invoiceNumber,
    List<CartItemModel>? items,
  }) {
    return CartModel(
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      items: items ?? this.items,
      createdAt: createdAt,
    );
  }
}
