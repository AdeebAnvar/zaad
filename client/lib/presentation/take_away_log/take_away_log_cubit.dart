import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';

part 'take_away_log_state.dart';

class TakeAwayLogCubit extends Cubit<TakeAwayLogState> {
  TakeAwayLogCubit(
    this.orderRepo, {
    HubOrdersLiveSync? hubOrdersLive,
  })  : _hubLive = hubOrdersLive,
        super(TakeAwayLogInitial()) {
    loadOrders();
    _attachHubLive();
  }

  final OrderRepository orderRepo;
  final HubOrdersLiveSync? _hubLive;
  void Function()? _detachHubLive;

  void _attachHubLive() {
    final h = _hubLive;
    if (h == null) return;
    void onRev() {
      if (isClosed) return;
      unawaited(refreshOrders());
    }

    h.revision.addListener(onRev);
    _detachHubLive = () => h.revision.removeListener(onRev);
  }

  Future<void> loadOrders() async {
    emit(TakeAwayLogLoading());
    try {
      var orders = await orderRepo.filterOrders(orderType: 'take_away');
      orders = orders.where((o) => o.status == 'kot').toList();
      emit(TakeAwayLogLoaded(orders));
    } catch (e) {
      emit(TakeAwayLogError(e.toString()));
    }
  }

  Future<void> refreshOrders() async {
    await loadOrders();
  }

  Future<void> filterOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) async {
    emit(TakeAwayLogLoading());
    try {
      var orders = await orderRepo.filterOrders(
        invoiceNumber: invoiceNumber,
        referenceNumber: referenceNumber,
        status: status,
        orderType: 'take_away',
        startDate: startDate,
        endDate: endDate,
        userId: userId,
      );
      if (status == null || status.isEmpty || status == 'All') {
        orders = orders.where((o) => o.status == 'kot').toList();
      } else if (status != 'completed') {
        orders = orders.where((o) => o.status != 'completed').toList();
      } else {
        orders = [];
      }
      emit(TakeAwayLogLoaded(orders));
    } catch (e) {
      emit(TakeAwayLogError(e.toString()));
    }
  }

  Future<void> deleteOrder(int orderId) async {
    try {
      await orderRepo.deleteOrder(orderId);
      await loadOrders(); // Reload orders after deletion
    } catch (e) {
      emit(TakeAwayLogError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _detachHubLive?.call();
    return super.close();
  }
}
