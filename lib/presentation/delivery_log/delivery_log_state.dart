part of 'delivery_log_cubit.dart';

abstract class DeliveryLogState {}

class DeliveryLogInitial extends DeliveryLogState {}

class DeliveryLogLoading extends DeliveryLogState {}

class DeliveryLogLoaded extends DeliveryLogState {
  final List<Order> orders;
  final String? selectedPartner;
  /// Partners from local DB / sync (same source as delivery service popup).
  final List<DeliveryPartner> deliveryPartners;

  DeliveryLogLoaded(
    this.orders,
    this.selectedPartner,
    this.deliveryPartners,
  );
}

class DeliveryLogError extends DeliveryLogState {
  final String message;

  DeliveryLogError(this.message);
}
