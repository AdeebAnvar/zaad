import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/constants/order_log_list_limits.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/utils/hub_log_order_user_scope.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';
import 'package:pos/data/repository/driver_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/core/debug/agent_debug_log.dart';
import 'package:pos/core/print/cash_drawer_on_payment.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';

part 'delivery_log_state.dart';

/// Delivery Sale Log: only the "Pending" phase (not yet dispatched / not closed).
/// Delivered, cancelled, and out-for-delivery rows belong in Driver Log or order history.
const List<String> _kDeliverySaleLogPendingStatuses = ['placed', 'pending', 'kot'];

/// Sale-log phase only (placed / pending / KOT). Payment may already be recorded at Save.
bool deliveryLogOrderVisible(Order o) {
  return _kDeliverySaleLogPendingStatuses.contains(o.status.toLowerCase());
}

/// True while the order is still in the sale-log phase (not dispatched / closed).
bool isDeliverySaleLogPendingStatus(String status) =>
    _kDeliverySaleLogPendingStatuses.contains(status.toLowerCase());

/// Pay is not offered in sale log while status is still Pending (use counter Save or Driver Log).
bool deliveryLogShowPayAction(Order order) =>
    !isDeliverySaleLogPendingStatus(order.status);

List<Order> _filterDeliveryLogList(List<Order> orders) {
  return orders.where(deliveryLogOrderVisible).toList();
}

bool _isNormalOrder(Order o) => o.deliveryPartner?.trim().toUpperCase() == 'NORMAL';

bool _hasDriver(Order o) => o.driverId != null && (o.driverName?.trim().isNotEmpty ?? false);

class DeliveryLogCubit extends Cubit<DeliveryLogState> {
  DeliveryLogCubit(
    this.orderRepo,
    this.deliveryPartnerRepo,
    this.driverRepo,
    this.hubSettings,
    this.counterSession, {
    HubOrdersLiveSync? hubOrdersLive,
  })  : _hubLive = hubOrdersLive,
        super(DeliveryLogInitial()) {
    loadOrders();
    _attachHubLive();
  }

  final OrderRepository orderRepo;
  final DeliveryPartnerRepository deliveryPartnerRepo;
  final DriverRepository driverRepo;
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
        sharedBranchLogsOnSub: true,
      );

  String? _selectedPartner;
  final Set<int> _normalSelection = {};

  void selectPartnerTab(String? partner) {
    _selectedPartner = partner;
    if (partner == null || partner.toUpperCase() != 'NORMAL') {
      _normalSelection.clear();
    }
    if (partner == null) {
      loadOrders();
    } else {
      filterOrders();
    }
  }

  void toggleNormalSelection(int orderId) {
    if (_normalSelection.contains(orderId)) {
      _normalSelection.remove(orderId);
    } else {
      _normalSelection.add(orderId);
    }
    if (state is DeliveryLogLoaded) {
      final s = state as DeliveryLogLoaded;
      emit(DeliveryLogLoaded(
        s.orders,
        s.selectedPartner,
        s.deliveryPartners,
        s.drivers,
        Set<int>.from(_normalSelection),
      ));
    }
  }

  void clearNormalSelection() {
    _normalSelection.clear();
    if (state is DeliveryLogLoaded) {
      final s = state as DeliveryLogLoaded;
      emit(DeliveryLogLoaded(
        s.orders,
        s.selectedPartner,
        s.deliveryPartners,
        s.drivers,
        const <int>{},
      ));
    }
  }

  Future<void> loadOrders() async {
    emit(DeliveryLogLoading());
    await _reloadOrders(userId: _scopedUserId(uiUserId: null));
  }

  Future<void> refreshOrders() async {
    await _reloadOrders(userId: _scopedUserId(uiUserId: null));
  }

  Future<void> filterOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? deliveryPartner,
    String? customerPhone,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) async {
    if (deliveryPartner != null && deliveryPartner.trim().isNotEmpty) {
      _selectedPartner = deliveryPartner.trim();
    }
    await _reloadOrders(
      invoiceNumber: invoiceNumber,
      referenceNumber: referenceNumber,
      customerPhone: customerPhone,
      status: status,
      startDate: startDate,
      endDate: endDate,
      userId: _scopedUserId(uiUserId: userId),
    );
  }

  Future<void> _reloadOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? customerPhone,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) async {
    final prior = state;
    try {
      final partners = await deliveryPartnerRepo.getAll();
      final drivers = await driverRepo.getAll();
      final partnerForQuery = _selectedPartner?.trim();
      var orders = await orderRepo.filterOrdersForList(
        invoiceNumber: invoiceNumber,
        referenceNumber: referenceNumber,
        orderType: 'delivery',
        deliveryPartner: partnerForQuery != null && partnerForQuery.isNotEmpty ? partnerForQuery : null,
        customerPhone: customerPhone,
        status: status,
        statusAnyOf: _kDeliverySaleLogPendingStatuses,
        startDate: startDate,
        endDate: endDate,
        userId: userId,
        limit: orderLogDefaultQueryLimit(
          invoiceNumber: invoiceNumber,
          referenceNumber: referenceNumber,
          customerPhone: customerPhone,
          startDate: startDate,
          endDate: endDate,
        ),
      );
      orders = _filterDeliveryLogList(orders);
      sortOrdersNewestFirst(orders);
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H1-H4',
        location: 'delivery_log_cubit.dart:_reloadOrders',
        message: 'delivery_log_reload',
        data: <String, Object?>{
          'pendingCount': orders.length,
          'queryStatusFilter': status,
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
      _normalSelection.removeWhere((id) => !orders.any((o) => o.id == id));
      emit(DeliveryLogLoaded(
        orders,
        _selectedPartner,
        partners,
        drivers,
        Set<int>.from(_normalSelection),
      ));
    } catch (e) {
      if (prior is DeliveryLogLoaded) {
        emit(prior);
      } else {
        emit(DeliveryLogError(e.toString()));
      }
    }
  }

  Future<void> deleteOrder(int orderId) async {
    try {
      await orderRepo.deleteOrder(orderId);
      _normalSelection.remove(orderId);
      await loadOrders();
    } catch (e) {
      emit(DeliveryLogError(e.toString()));
    }
  }

  /// Returns an error message to show in UI, or null on success.
  Future<String?> updateOrderStatus(int orderId, String newStatus) async {
    final order = await orderRepo.getOrderById(orderId);
    if (order == null) return 'Order not found.';
    if (_isNormalOrder(order)) {
      final s = newStatus.toLowerCase();
      if ((s == 'out_of_delivery' || s == 'assigned' || s == 'dispatched') && !_hasDriver(order)) {
        return 'Assign a driver before marking out for delivery.';
      }
      final cur = order.status.toLowerCase();
      if (s == 'pending' && (cur == 'assigned' || cur == 'out_of_delivery' || cur == 'dispatched' || cur == 'delivered' || cur == 'completed')) {
        return 'Cannot change status back to Pending after dispatch.';
      }
    }
    try {
      await orderRepo.updateOrderStatus(orderId, newStatus);
      final after = await orderRepo.getOrderById(orderId);
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H2-H5',
        location: 'delivery_log_cubit.dart:updateOrderStatus',
        message: 'delivery_status_updated',
        data: <String, Object?>{
          'orderId': orderId,
          'requestedStatus': newStatus,
          'dbStatusAfter': after?.status,
          'invoice': after?.invoiceNumber,
        },
      );
      // #endregion
      await loadOrders();
      return null;
    } catch (e) {
      emit(DeliveryLogError(e.toString()));
      return e.toString();
    }
  }

  /// Assign driver and set status to [out_of_delivery] for Normal delivery orders. Returns error message or null.
  Future<String?> assignDriverToOrders(List<int> orderIds, int driverId, String driverName) async {
    if (orderIds.isEmpty) return 'Select at least one order.';
    try {
      for (final id in orderIds) {
        final order = await orderRepo.getOrderById(id);
        if (order == null) continue;
        if (order.deliveryPartner?.trim().toUpperCase() != 'NORMAL') continue;
        await orderRepo.updateOrder(
          order.copyWith(
            driverId: Value(driverId),
            driverName: Value(driverName),
            status: 'out_of_delivery',
          ),
        );
      }
      for (final id in orderIds) {
        _normalSelection.remove(id);
      }
      await loadOrders();
      return null;
    } catch (e) {
      return e.toString();
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
      final updated = order.copyWith(
        cashAmount: cash,
        cardAmount: card,
        creditAmount: credit,
        onlineAmount: online,
      );
      await orderRepo.updateOrder(updated);
      if (paymentType == 'CASH') {
        await openCashDrawerForCashPayment(finalAmount);
      }
      final after = await orderRepo.getOrderById(orderId);
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H1',
        location: 'delivery_log_cubit.dart:updateOrderPaymentType',
        message: 'delivery_payment_only',
        data: <String, Object?>{
          'orderId': orderId,
          'paymentType': paymentType,
          'dbStatusAfter': after?.status,
          'paid': after == null
              ? null
              : after.cashAmount + after.cardAmount + after.creditAmount + after.onlineAmount,
          'finalAmount': after?.finalAmount,
        },
      );
      // #endregion
      await loadOrders();
    } catch (e) {
      emit(DeliveryLogError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _detachHubLive?.call();
    return super.close();
  }
}
