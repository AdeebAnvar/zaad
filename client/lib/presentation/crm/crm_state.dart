part of 'crm_cubit.dart';

abstract class CrmState {}

class CrmInitial extends CrmState {}

class CrmLoading extends CrmState {}

class CrmLoaded extends CrmState {
  final List<CustomerWithOrders> customers;

  CrmLoaded(this.customers);
}

class CrmError extends CrmState {
  final String message;

  CrmError(this.message);
}
