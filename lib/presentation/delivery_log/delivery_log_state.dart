part of 'delivery_log_cubit.dart';

abstract class DeliveryLogState {}

class DeliveryLogInitial extends DeliveryLogState {}

class DeliveryLogLoading extends DeliveryLogState {}

class DeliveryLogLoaded extends DeliveryLogState {
  final List<Order> orders;
  final String? selectedPartner;
  /// Partners from local DB / sync (same source as delivery service popup).
  final List<DeliveryPartner> deliveryPartners;
  /// Drivers from local DB / sync (for Normal delivery assignment).
  final List<Driver> drivers;
  /// Selected Normal-delivery order ids (bulk assign). Only used when [selectedPartner] is NORMAL.
  final Set<int> normalSelection;

  DeliveryLogLoaded(
    this.orders,
    this.selectedPartner,
    this.deliveryPartners,
    this.drivers,
    this.normalSelection,
  );
}

class DeliveryLogError extends DeliveryLogState {
  final String message;

  DeliveryLogError(this.message);
}
