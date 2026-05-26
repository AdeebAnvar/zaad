import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/constants/order_log_list_limits.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/utils/hub_log_order_user_scope.dart';
import 'package:pos/core/utils/order_display_utils.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/core/utils/order_payment_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';

part 'recent_sales_state.dart';

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

  int _page = 1;
  String? _invoiceNumber;
  String? _referenceNumber;
  String? _status;
  String? _orderType;
  String? _paymentMethod;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _userId;

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
    _page = 1;
    _invoiceNumber = null;
    _referenceNumber = null;
    _status = null;
    _orderType = null;
    _paymentMethod = null;
    _startDate = null;
    _endDate = null;
    _userId = null;
    emit(RecentSalesLoading());
    await _reloadOrders();
  }

  Future<void> refreshOrders() async {
    await _reloadOrders();
  }

  Future<void> goToPage(int page) async {
    if (page < 1) return;
    final loaded = state;
    if (loaded is RecentSalesLoaded) {
      final totalPages = loaded.totalPages;
      if (totalPages > 0 && page > totalPages) return;
    }
    _page = page;
    await _reloadOrders();
  }

  Future<void> nextPage() => goToPage(_page + 1);

  Future<void> previousPage() => goToPage(_page - 1);

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
    _page = 1;
    _invoiceNumber = invoiceNumber;
    _referenceNumber = referenceNumber;
    _status = status;
    _orderType = orderType;
    _paymentMethod = paymentMethod;
    _startDate = startDate;
    _endDate = endDate;
    _userId = _scopedUserId(uiUserId: userId);
    await _reloadOrders();
  }

  Future<void> _reloadOrders() async {
    final prior = state;
    if (prior is RecentSalesLoaded) {
      emit(prior.copyWith(isPageLoading: true));
    }

    try {
      final dbOrderType = orderTypeFilterToDb(_orderType);
      final useDefaultSettledView =
          _status == null || _status!.isEmpty || _status == 'All';
      final dbStatus = useDefaultSettledView ? null : _status;
      final userId = _userId ?? _scopedUserId(uiUserId: null);

      List<Order> orders;
      late final int totalCount;

      if (useDefaultSettledView) {
        var settled = await orderRepo.filterOrdersForList(
          invoiceNumber: _invoiceNumber,
          referenceNumber: _referenceNumber,
          orderType: dbOrderType,
          startDate: _startDate,
          endDate: _endDate,
          userId: userId,
          limit: orderLogDefaultQueryLimit(
            invoiceNumber: _invoiceNumber,
            referenceNumber: _referenceNumber,
            startDate: _startDate,
            endDate: _endDate,
          ),
        );
        settled = settled.where(orderCountsAsRecentSale).toList();
        sortOrdersNewestFirst(settled);
        totalCount = settled.length;
        final totalPages = totalCount == 0 ? 1 : (totalCount / kRecentSalesPageSize).ceil();
        if (_page > totalPages) {
          _page = totalPages;
        }
        final offset = (_page - 1) * kRecentSalesPageSize;
        orders = settled.skip(offset).take(kRecentSalesPageSize).toList();
      } else {
        totalCount = await orderRepo.countOrdersForList(
          invoiceNumber: _invoiceNumber,
          referenceNumber: _referenceNumber,
          status: dbStatus,
          orderType: dbOrderType,
          startDate: _startDate,
          endDate: _endDate,
          userId: userId,
        );

        final totalPages = totalCount == 0 ? 1 : (totalCount / kRecentSalesPageSize).ceil();
        if (_page > totalPages) {
          _page = totalPages;
        }

        final offset = (_page - 1) * kRecentSalesPageSize;

        orders = await orderRepo.filterOrdersForList(
          invoiceNumber: _invoiceNumber,
          referenceNumber: _referenceNumber,
          status: dbStatus,
          orderType: dbOrderType,
          startDate: _startDate,
          endDate: _endDate,
          userId: userId,
          limit: kRecentSalesPageSize,
          offset: offset,
        );
        orders = orders.where((order) => order.status != 'kot').toList();
      }

      if (_paymentMethod != null && _paymentMethod!.isNotEmpty) {
        orders = orders.where((order) {
          switch (_paymentMethod!.toLowerCase()) {
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
        orders: orders,
        currentPage: _page,
        totalCount: totalCount,
        pageSize: kRecentSalesPageSize,
      ));
    } catch (e) {
      if (prior is RecentSalesLoaded) {
        emit(prior.copyWith(isPageLoading: false));
      } else {
        emit(RecentSalesError(e.toString()));
      }
    }
  }

  Future<void> deleteOrder(int orderId) async {
    try {
      await orderRepo.deleteOrder(orderId);
      final loaded = state;
      if (loaded is RecentSalesLoaded && loaded.orders.length == 1 && _page > 1) {
        _page -= 1;
      }
      await _reloadOrders();
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
