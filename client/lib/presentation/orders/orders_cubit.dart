import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';

part 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(
    this.orderRepo, {
    HubOrdersLiveSync? hubOrdersLive,
  })  : _hubLive = hubOrdersLive,
        super(OrdersInitial()) {
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
      unawaited(loadOrders());
    }

    h.revision.addListener(onRev);
    _detachHubLive = () => h.revision.removeListener(onRev);
  }

  Future<void> loadOrders() async {
    emit(OrdersLoading());
    try {
      final orders = await orderRepo.getAllOrders();
      // Filter only completed orders
      final completedOrders = orders.where((o) => o.status == 'completed').toList();
      sortOrdersNewestFirst(completedOrders);
      emit(OrdersLoaded(completedOrders));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _detachHubLive?.call();
    return super.close();
  }
}
