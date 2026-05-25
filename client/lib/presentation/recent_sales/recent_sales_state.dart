part of 'recent_sales_cubit.dart';

abstract class RecentSalesState {
  const RecentSalesState();
}

class RecentSalesInitial extends RecentSalesState {}

class RecentSalesLoading extends RecentSalesState {}

class RecentSalesLoaded extends RecentSalesState {
  final List<Order> orders;
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final bool isPageLoading;

  const RecentSalesLoaded({
    required this.orders,
    required this.currentPage,
    required this.totalCount,
    required this.pageSize,
    this.isPageLoading = false,
  });

  int get totalPages => totalCount == 0 ? 1 : (totalCount / pageSize).ceil();

  int get rangeStart => totalCount == 0 ? 0 : (currentPage - 1) * pageSize + 1;

  int get rangeEnd {
    if (totalCount == 0) return 0;
    final end = currentPage * pageSize;
    return end > totalCount ? totalCount : end;
  }

  bool get hasPreviousPage => currentPage > 1;

  bool get hasNextPage => currentPage < totalPages;

  RecentSalesLoaded copyWith({
    List<Order>? orders,
    int? currentPage,
    int? totalCount,
    int? pageSize,
    bool? isPageLoading,
  }) {
    return RecentSalesLoaded(
      orders: orders ?? this.orders,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      pageSize: pageSize ?? this.pageSize,
      isPageLoading: isPageLoading ?? this.isPageLoading,
    );
  }
}

class RecentSalesError extends RecentSalesState {
  final String message;

  RecentSalesError(this.message);
}
