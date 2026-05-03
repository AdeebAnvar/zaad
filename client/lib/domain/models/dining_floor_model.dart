class DiningFloorModel {
  const DiningFloorModel({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });

  final int id;
  final String name;
  final int sortOrder;

  factory DiningFloorModel.fromJson(Map<String, dynamic> json) {
    final rawSort = json['sortOrder'] ?? json['sort_order'] ?? 0;
    return DiningFloorModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      sortOrder: (rawSort as num).toInt(),
    );
  }
}
