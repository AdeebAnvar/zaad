part of 'recent_sales_cubit.dart';

abstract class RecentSalesState {
  const RecentSalesState();
}

class RecentSalesInitial extends RecentSalesState {}

class RecentSalesLoading extends RecentSalesState {}

class RecentSalesLoaded extends RecentSalesState {
  final List<Order> orders;

  RecentSalesLoaded(this.orders);
}

class RecentSalesError extends RecentSalesState {
  final String message;

  RecentSalesError(this.message);
}
