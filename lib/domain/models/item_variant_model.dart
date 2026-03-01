class ItemVariant {
  final int id;
  final String name;
  final double price;

  const ItemVariant({
    required this.id,
    required this.name,
    required this.price,
  });

  factory ItemVariant.fromJson(Map<String, dynamic> json) {
    return ItemVariant(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }
}
