import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/network/websocket_service.dart';

/// Example: pulls `GET /orders` + hydrates cache (show error from [OrderHubRefreshState.error]).
class OrderHubRefreshState {
  const OrderHubRefreshState({
    required this.busy,
    this.error,
    this.doneAt,
  });

  final bool busy;
  final String? error;
  final DateTime? doneAt;
}

class OrderHubRefreshCubit extends Cubit<OrderHubRefreshState> {
  OrderHubRefreshCubit(this._hub) : super(const OrderHubRefreshState(busy: false));

  final HubWebSocketService _hub;

  Future<void> refreshHubCache() async {
    emit(OrderHubRefreshState(busy: true, error: null, doneAt: state.doneAt));
    try {
      await _hub.hydrateCacheIfConfigured();
      emit(OrderHubRefreshState(busy: false, doneAt: DateTime.now()));
    } catch (e) {
      emit(OrderHubRefreshState(
        busy: false,
        error: '$e',
        doneAt: state.doneAt,
      ));
    }
  }
}
