import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/utils/hub_log_order_user_scope.dart';
import 'package:pos/core/utils/order_display_utils.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';

part 'recent_sales_state.dart';

/// Default cap when the list is not narrowed by receipt/reference/date search.
const int kRecentSalesDefaultListLimit = 400;

class RecentSalesCubit extends Cubit<RecentSalesState> {
  RecentSalesCubit(
    this.orderRepo,
    this.hubSettings,
    this.counterSession, {
    HubOrdersLiveSync? hubOrdersLive,
  })  : _hubLive = hubOrdersLive,
        super(RecentSalesInitial()) {
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

  static bool _useDefaultLimit({
    String? invoiceNumber,
    String? referenceNumber,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final hasInvoice = invoiceNumber != null && invoiceNumber.trim().isNotEmpty;
    final hasRef = referenceNumber != null && referenceNumber.trim().isNotEmpty;
    return !hasInvoice && !hasRef && startDate == null && endDate == null;
  }

  Future<void> loadOrders() async {
    emit(RecentSalesLoading());
    await _reloadOrders();
  }

  Future<void> refreshOrders() async {
    await _reloadOrders();
  }

  Future<void> filterOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? status,
    String? orderType,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) async {
    await _reloadOrders(
      invoiceNumber: invoiceNumber,
      referenceNumber: referenceNumber,
      status: status,
      orderType: orderType,
      paymentMethod: paymentMethod,
      startDate: startDate,
      endDate: endDate,
      userId: _scopedUserId(uiUserId: userId),
    );
  }

  Future<void> _reloadOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? status,
    String? orderType,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) async {
    final prior = state;
    try {
      final dbOrderType = orderTypeFilterToDb(orderType);
      final narrowed = !_useDefaultLimit(
        invoiceNumber: invoiceNumber,
        referenceNumber: referenceNumber,
        startDate: startDate,
        endDate: endDate,
      );

      var orders = await orderRepo.filterOrders(
        invoiceNumber: invoiceNumber,
        referenceNumber: referenceNumber,
        status: status == null || status == 'All' ? 'completed' : status,
        orderType: dbOrderType,
        startDate: startDate,
        endDate: endDate,
        userId: userId ?? _scopedUserId(uiUserId: null),
        limit: narrowed ? null : kRecentSalesDefaultListLimit,
      );

      if (status == null || status.isEmpty || status == 'All') {
        orders = orders.where((order) => order.status == 'completed').toList();
      } else {
        orders = orders.where((order) => order.status != 'kot').toList();
      }

      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        orders = orders.where((order) {
          switch (paymentMethod.toLowerCase()) {
            case 'cash':
              return order.cashAmount > 0;
            case 'card':
              return order.cardAmount > 0;
            case 'credit':
              return order.creditAmount > 0;
            case 'online':
              return order.onlineAmount > 0;
            default:
              return true;
          }
        }).toList();
      }

      sortOrdersNewestFirst(orders);
      emit(RecentSalesLoaded(
        orders,
        cappedToLatest: !narrowed && orders.length >= kRecentSalesDefaultListLimit,
      ));
    } catch (e) {
      if (prior is RecentSalesLoaded) {
        emit(prior);
      } else {
        emit(RecentSalesError(e.toString()));
      }
    }
  }

  Future<void> deleteOrder(int orderId) async {
    try {
      await orderRepo.deleteOrder(orderId);
      await loadOrders();
    } catch (e) {
      emit(RecentSalesError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _detachHubLive?.call();
    return super.close();
  }
}
