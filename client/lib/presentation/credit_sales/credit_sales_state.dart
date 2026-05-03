part of 'credit_sales_cubit.dart';

sealed class CreditSalesState {}

class CreditSalesInitial extends CreditSalesState {}

class CreditSalesLoading extends CreditSalesState {}

class CreditSalesError extends CreditSalesState {
  CreditSalesError(this.message);
  final String message;
}

class CreditSalesLoaded extends CreditSalesState {
  CreditSalesLoaded({
    required this.filteredOrders,
    required this.filterQuery,
  });

  final List<Order> filteredOrders;
  final String filterQuery;
}
