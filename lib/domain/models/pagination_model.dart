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
        currentPage: json["current_page"],
        lastPage: json["last_page"],
        perPage: json["per_page"],
        total: json["total"],
        hasMore: json["has_more"],
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "last_page": lastPage,
        "per_page": perPage,
        "total": total,
        "has_more": hasMore,
      };
}
