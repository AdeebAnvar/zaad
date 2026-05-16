import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/utils/hub_log_order_user_scope.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';

part 'take_away_log_state.dart';

class TakeAwayLogCubit extends Cubit<TakeAwayLogState> {
  TakeAwayLogCubit(
    this.orderRepo,
    this.hubSettings,
    this.counterSession, {
    HubOrdersLiveSync? hubOrdersLive,
  })  : _hubLive = hubOrdersLive,
        super(TakeAwayLogInitial()) {
    loadOrders();
    _attachHubLive();
  }

  final OrderRepository orderRepo;
  final LocalHubSettings hubSettings;
  final CurrentCounterSession counterSession;
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

  int? _scopedUserId({int? uiUserId}) => HubLogOrderUserScope.effectiveFilterUserId(
        hub: hubSettings,
        sessionUser: counterSession.user,
        uiSelectedUserId: uiUserId,
      );

  Future<void> loadOrders() async {
    emit(TakeAwayLogLoading());
    await _reloadOrders(
      userId: _scopedUserId(uiUserId: null),
    );
  }

  /// Hub live sync / pull-to-refresh — keep filter fields mounted (no Loading flash).
  Future<void> refreshOrders() async {
    await _reloadOrders(userId: _scopedUserId(uiUserId: null));
  }

  Future<void> filterOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) async {
    await _reloadOrders(
      invoiceNumber: invoiceNumber,
      referenceNumber: referenceNumber,
      status: status,
      startDate: startDate,
      endDate: endDate,
      userId: _scopedUserId(uiUserId: userId),
    );
  }

  Future<void> _reloadOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) async {
    final prior = state;
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
      sortOrdersNewestFirst(orders);
      emit(TakeAwayLogLoaded(orders));
    } catch (e) {
      if (prior is TakeAwayLogLoaded) {
        emit(prior);
      } else {
        emit(TakeAwayLogError(e.toString()));
      }
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

  Future<void> updateOrderPaymentType(int orderId, String paymentType, double finalAmount) async {
    try {
      final order = await orderRepo.getOrderById(orderId);
      if (order == null) return;
      final updated = order.copyWith(
        cashAmount: paymentType == 'CASH' ? finalAmount : 0,
        cardAmount: paymentType == 'CARD' ? finalAmount : 0,
        creditAmount: paymentType == 'CREDIT' ? finalAmount : 0,
        onlineAmount: paymentType == 'ONLINE' ? finalAmount : 0,
      );
      await orderRepo.updateOrder(updated);
      await loadOrders();
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
