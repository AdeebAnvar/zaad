class DiningTableModel {
  const DiningTableModel({
    required this.id,
    required this.floorId,
    required this.code,
    required this.chairs,
    required this.status,
  });

  final int id;
  final int floorId;
  final String code;
  final int chairs;
  final String status;

  factory DiningTableModel.fromJson(Map<String, dynamic> json) {
    final rawFloorId = json['floorId'] ?? json['floor_id'] ?? 0;
    final rawChairs = json['chairs'] ?? json['chair_count'] ?? 4;
    return DiningTableModel(
      id: (json['id'] as num).toInt(),
      floorId: (rawFloorId as num).toInt(),
      code: (json['code'] ?? json['name'] ?? '').toString(),
      chairs: (rawChairs as num).toInt(),
      status: ((json['status'] ?? 'free').toString()).toLowerCase(),
    );
  }
}
