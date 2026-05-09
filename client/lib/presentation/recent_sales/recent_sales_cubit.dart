import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/utils/order_display_utils.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';

part 'recent_sales_state.dart';

class RecentSalesCubit extends Cubit<RecentSalesState> {
  RecentSalesCubit(
    this.orderRepo, {
    HubOrdersLiveSync? hubOrdersLive,
  })  : _hubLive = hubOrdersLive,
        super(RecentSalesInitial()) {
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
    emit(RecentSalesLoading());
    try {
      // Recent Sales = paid orders only (completed). Exclude kot (unpaid, in Take Away Log)
      final allOrders = await orderRepo.getAllOrders();
      final filteredOrders = allOrders.where((order) => order.status == 'completed').toList();
      sortOrdersNewestFirst(filteredOrders);
      emit(RecentSalesLoaded(filteredOrders));
    } catch (e) {
      emit(RecentSalesError(e.toString()));
    }
  }

  Future<void> refreshOrders() async {
    await loadOrders();
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
    emit(RecentSalesLoading());
    try {
      final dbOrderType = orderTypeFilterToDb(orderType);

      // First filter by status, date, invoice, reference, order type (all channels)
      var orders = await orderRepo.filterOrders(
        invoiceNumber: invoiceNumber,
        referenceNumber: referenceNumber,
        status: status == null || status == 'All' ? null : status,
        orderType: dbOrderType,
        startDate: startDate,
        endDate: endDate,
        userId: userId,
      );

      // Recent Sales default: completed only. If user picks a status, respect it (except hide kot noise).
      if (status == null || status.isEmpty || status == 'All') {
        orders = orders.where((order) => order.status == 'completed').toList();
      } else {
        orders = orders.where((order) => order.status != 'kot').toList();
      }

      // Filter by payment method
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
      emit(RecentSalesLoaded(orders));
    } catch (e) {
      emit(RecentSalesError(e.toString()));
    }
  }

  Future<void> deleteOrder(int orderId) async {
    try {
      await orderRepo.deleteOrder(orderId);
      await loadOrders(); // Reload orders after deletion
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
