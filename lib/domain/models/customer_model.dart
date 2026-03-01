class CustomerModel {
  final int? id;
  final String? serverId;
  final String name;
  final String? email;
  final String? phone;
  final String? gender;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSynced;

  CustomerModel({
    this.id,
    this.serverId,
    required this.name,
    this.email,
    this.phone,
    this.gender,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': serverId ?? id,
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      serverId: json['id']?.toString(),
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      gender: json['gender'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isSynced: true,
    );
  }

  CustomerModel copyWith({
    int? id,
    String? serverId,
    String? name,
    String? email,
    String? phone,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
