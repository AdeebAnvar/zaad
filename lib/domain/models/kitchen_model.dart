class KitchenModel {
  final int id;
  final String name;
  final String? printerIp;
  final int printerPort;

  KitchenModel({
    required this.id,
    required this.name,
    this.printerIp,
    this.printerPort = 9100,
  });

  factory KitchenModel.fromJson(Map<String, dynamic> json) {
    return KitchenModel(
      id: json['id'] as int,
      name: json['name'] as String,
      printerIp: json['printer_ip'] as String?,
      printerPort: json['printer_port'] as int? ?? 9100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (printerIp != null) 'printer_ip': printerIp,
      'printer_port': printerPort,
    };
  }
}
