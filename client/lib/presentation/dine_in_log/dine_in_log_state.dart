part of 'dine_in_log_cubit.dart';

abstract class DineInLogState {}

class DineInLogInitial extends DineInLogState {}

class DineInLogLoading extends DineInLogState {}

class DineInLogLoaded extends DineInLogState {
  DineInLogLoaded(this.orders, this.cartLineCountsByCartId);
  final List<Order> orders;
  final Map<int, int> cartLineCountsByCartId;
}

class DineInLogError extends DineInLogState {
  DineInLogError(this.message);
  final String message;
}
