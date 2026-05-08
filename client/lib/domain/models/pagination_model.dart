class PaginationModel {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  PaginationModel({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.hasMore,
  });

  factory PaginationModel.fallback() => PaginationModel(
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 0,
        hasMore: false,
      );

  PaginationModel copyWith({
    int? currentPage,
    int? lastPage,
    int? perPage,
    int? total,
    bool? hasMore,
  }) =>
      PaginationModel(
        currentPage: currentPage ?? this.currentPage,
        lastPage: lastPage ?? this.lastPage,
        perPage: perPage ?? this.perPage,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
      );

  factory PaginationModel.fromJson(Map<String, dynamic> json) => PaginationModel(
        currentPage: (json["current_page"] as num?)?.toInt() ?? 0,
        lastPage: (json["last_page"] as num?)?.toInt() ?? 0,
        perPage: (json["per_page"] as num?)?.toInt() ?? 0,
        total: (json["total"] as num?)?.toInt() ?? 0,
        hasMore: json["has_more"] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "last_page": lastPage,
        "per_page": perPage,
        "total": total,
        "has_more": hasMore,
      };
}
