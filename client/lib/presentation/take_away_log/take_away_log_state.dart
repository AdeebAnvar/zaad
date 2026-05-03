part of 'take_away_log_cubit.dart';

abstract class TakeAwayLogState {}

class TakeAwayLogInitial extends TakeAwayLogState {}

class TakeAwayLogLoading extends TakeAwayLogState {}

class TakeAwayLogLoaded extends TakeAwayLogState {
  final List<Order> orders;

  TakeAwayLogLoaded(this.orders);
}

class TakeAwayLogError extends TakeAwayLogState {
  final String message;

  TakeAwayLogError(this.message);
}
