class DeliveryPartnerModel {
  final int id;
  final String name;

  DeliveryPartnerModel({
    required this.id,
    required this.name,
  });

  factory DeliveryPartnerModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
