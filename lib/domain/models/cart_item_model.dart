import 'package:pos/data/local/drift_database.dart';

class CartItemModel {
  final Item item;
  final ItemVariant? itemVariant;
  final ItemToppings? itemToppings;
  final int quantity;
  final double discount;
  final int? cartId;

  const CartItemModel({
    this.cartId,
    required this.item,
    this.itemVariant,
    this.itemToppings,
    this.quantity = 1,
    this.discount = 0,
  });

  double get unitPrice => itemVariant?.price ?? item.price;

  double get total => (unitPrice * quantity) - discount;

  CartItemModel copyWith({
    int? quantity,
    double? discount,
    int? cartId,
  }) {
    return CartItemModel(
      item: item,
      cartId: cartId ?? this.cartId,
      itemVariant: itemVariant,
      itemToppings: itemToppings,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }
}
