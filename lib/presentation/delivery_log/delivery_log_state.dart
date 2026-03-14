part of 'delivery_log_cubit.dart';

abstract class DeliveryLogState {}

class DeliveryLogInitial extends DeliveryLogState {}

class DeliveryLogLoading extends DeliveryLogState {}

class DeliveryLogLoaded extends DeliveryLogState {
  final List<Order> orders;

  DeliveryLogLoaded(this.orders);
}

class DeliveryLogError extends DeliveryLogState {
  final String message;

  DeliveryLogError(this.message);
}
