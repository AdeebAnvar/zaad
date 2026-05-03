class ItemTopping {
  final int id;
  final String name;
  final double price;
  final int maxQty;

  const ItemTopping({
    required this.id,
    required this.name,
    required this.price,
    this.maxQty = 1,
  });

  factory ItemTopping.fromJson(Map<String, dynamic> json) {
    return ItemTopping(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      maxQty: json['max_qty'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'max_qty': maxQty,
    };
  }
}
