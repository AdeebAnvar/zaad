import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/constants/order_log_list_limits.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/utils/hub_log_order_user_scope.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/core/debug/agent_debug_log.dart';
import 'package:pos/core/print/cash_drawer_on_payment.dart';
import 'package:pos/core/utils/order_payment_utils.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';

part 'take_away_log_state.dart';

/// Open takeaway bills only — hide fully paid KOT / pending rows (day close uses the same balance rules).
bool _takeAwayLogListVisible(Order o) {
  final s = o.status.toLowerCase();
  if (s == 'cancelled' || s == 'completed') return false;
  if (s != 'kot' && s != 'placed' && s != 'pending') return false;
  if (orderPayableAmount(o) <= 0.009) return true;
  return orderHasOutstandingBalance(o);
}

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
    int? pickupToken,
  }) async {
    await _reloadOrders(
      invoiceNumber: invoiceNumber,
      referenceNumber: referenceNumber,
      status: status,
      startDate: startDate,
      endDate: endDate,
      userId: _scopedUserId(uiUserId: userId),
      pickupToken: pickupToken,
    );
  }

  Future<void> _reloadOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
    int? pickupToken,
  }) async {
    final prior = state;
    try {
      final limit = orderLogDefaultQueryLimit(
        invoiceNumber: invoiceNumber,
        referenceNumber: referenceNumber,
        startDate: startDate,
        endDate: endDate,
      );
      var orders = pickupToken != null
          ? await orderRepo.filterOrders(
              invoiceNumber: invoiceNumber,
              referenceNumber: referenceNumber,
              status: status,
              orderType: 'take_away',
              startDate: startDate,
              endDate: endDate,
              userId: _scopedUserId(uiUserId: userId),
              pickupToken: pickupToken,
              limit: limit,
            )
          : await orderRepo.filterOrdersForList(
              invoiceNumber: invoiceNumber,
              referenceNumber: referenceNumber,
              status: status,
              orderType: 'take_away',
              startDate: startDate,
              endDate: endDate,
              userId: _scopedUserId(uiUserId: userId),
              limit: limit,
            );
      if (status == null || status.isEmpty || status == 'All') {
        orders = orders.where(_takeAwayLogListVisible).toList();
      } else if (status != 'completed') {
        orders = orders.where((o) => o.status != 'completed').toList();
      } else {
        orders = [];
      }
      sortOrdersNewestFirst(orders);
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H1-H3',
        location: 'take_away_log_cubit.dart:_reloadOrders',
        message: 'takeaway_log_reload',
        data: <String, Object?>{
          'kotCount': orders.length,
          'statusFilter': status,
          'rows': orders
              .take(6)
              .map(
                (o) => <String, Object?>{
                  'id': o.id,
                  'invoice': o.invoiceNumber,
                  'status': o.status,
                  'paid': o.cashAmount + o.cardAmount + o.creditAmount + o.onlineAmount,
                  'finalAmount': o.finalAmount,
                },
              )
              .toList(),
        },
      );
      // #endregion
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
      final cash = paymentType == 'CASH' ? finalAmount : 0.0;
      final card = paymentType == 'CARD' ? finalAmount : 0.0;
      final credit = paymentType == 'CREDIT' ? finalAmount : 0.0;
      final online = paymentType == 'ONLINE' ? finalAmount : 0.0;
      final fullyPaid = !orderHasOutstandingBalance(order);
      final s = order.status.toLowerCase();
      final closeWhenPaid = fullyPaid && (s == 'kot' || s == 'placed' || s == 'pending');
      final updated = order.copyWith(
        cashAmount: cash,
        cardAmount: card,
        creditAmount: credit,
        onlineAmount: online,
        status: closeWhenPaid ? 'completed' : order.status,
      );
      await orderRepo.updateOrder(updated);
      if (paymentType == 'CASH') {
        await openCashDrawerForCashPayment(finalAmount);
      }
      final after = await orderRepo.getOrderById(orderId);
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H1',
        location: 'take_away_log_cubit.dart:updateOrderPaymentType',
        message: 'takeaway_payment_only',
        data: <String, Object?>{
          'orderId': orderId,
          'paymentType': paymentType,
          'dbStatusAfter': after?.status,
          'paid': after == null
              ? null
              : after.cashAmount + after.cardAmount + after.creditAmount + after.onlineAmount,
        },
      );
      // #endregion
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
