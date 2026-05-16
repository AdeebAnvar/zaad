import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/utils/hub_log_order_user_scope.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:pos/presentation/dine_in_log/dine_in_reference_utils.dart';

part 'dine_in_log_state.dart';

bool dineInBillIsSplittable(Order order) {
  final s = order.status.toLowerCase();
  return order.orderType == 'dine_in' && (s == 'kot' || s == 'placed');
}

/// Dine-in log is for open bills only: no cancelled, no completed, no fully paid rows.
bool _dineInLogListVisible(Order o) {
  final s = o.status.toLowerCase();
  if (s == 'cancelled' || s == 'completed') return false;
  final payable = o.finalAmount > 0.009 ? o.finalAmount : o.totalAmount;
  if (payable <= 0.009) return true;
  final paid = o.cashAmount + o.cardAmount + o.creditAmount + o.onlineAmount;
  return paid + 0.02 < payable;
}

class DineInLogCubit extends Cubit<DineInLogState> {
  DineInLogCubit(
    this.orderRepo,
    this.cartRepo,
    this.hubSettings,
    this.counterSession, {
    HubOrdersLiveSync? hubOrdersLive,
  })  : _hubLive = hubOrdersLive,
        super(DineInLogInitial()) {
    loadOrders();
    _attachHubLive();
  }

  final OrderRepository orderRepo;
  final CartRepository cartRepo;
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
    emit(DineInLogLoading());
    await _reloadOrders(userId: _scopedUserId(uiUserId: null));
  }

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
        orderType: 'dine_in',
        startDate: startDate,
        endDate: endDate,
        userId: userId,
      );
      if (status == null || status.isEmpty || status == 'All') {
        orders = orders.where(_dineInLogListVisible).toList();
      } else {
        orders = orders.where((o) => o.status == status).where(_dineInLogListVisible).toList();
      }
      sortOrdersNewestFirst(orders);
      final cartIds = orders.map((o) => o.cartId).toSet().toList();
      final counts = await cartRepo.countCartItemsByCartIds(cartIds);
      emit(DineInLogLoaded(orders, counts));
    } catch (e) {
      if (prior is DineInLogLoaded) {
        emit(prior);
      } else {
        emit(DineInLogError(e.toString()));
      }
    }
  }

  Future<void> deleteOrder(int orderId) async {
    try {
      await orderRepo.deleteOrder(orderId);
      await loadOrders();
    } catch (e) {
      emit(DineInLogError(e.toString()));
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
      emit(DineInLogError(e.toString()));
    }
  }

  /// Updates dine-in routing in **hub metadata only**; clears [Order.referenceNumber] for dine-in.
  Future<String?> moveDineInOrderToTable({
    required int orderId,
    required String newReferenceNumber,
  }) async {
    try {
      final order = await orderRepo.getOrderById(orderId);
      if (order == null) return 'Order not found';
      final mergedHub = DineInRefParser.mergeHubMetadataAnchor(order.hubMetadata, newReferenceNumber);
      await orderRepo.updateOrder(
        order.copyWith(
          hubMetadata: Value(mergedHub),
          referenceNumber: const Value<String?>(null),
        ),
      );
      await loadOrders();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  double _sumLineTotals(List<CartItem> items) => items.fold<double>(0, (sum, e) => sum + e.total);

  Future<void> _syncOrderTotalsFromCart(Order order) async {
    final items = await cartRepo.getCartItemsByCartId(order.cartId) ?? [];
    final total = _sumLineTotals(items);
    await orderRepo.updateOrder(
      order.copyWith(
        totalAmount: total,
        finalAmount: total,
        discountAmount: 0,
        discountType: const Value<String?>(null),
      ),
    );
  }

  /// Move selected lines to a new bill (new cart + order). Clears order-level discounts; totals follow lines.
  Future<String?> splitDineInBill({
    required int sourceOrderId,
    required List<int> cartItemIdsToMove,
  }) async {
    try {
      if (cartItemIdsToMove.isEmpty) return 'Select at least one line to move';
      final source = await orderRepo.getOrderById(sourceOrderId);
      if (source == null) return 'Order not found';
      if (!dineInBillIsSplittable(source)) {
        return 'Only open bills (KOT / placed) can be split';
      }
      if (source.orderType != 'dine_in') return 'Not a dine-in order';

      final allItems = await cartRepo.getCartItemsByCartId(source.cartId) ?? [];
      final byId = {for (final i in allItems) i.id: i};
      if (cartItemIdsToMove.length >= allItems.length) {
        return 'Leave at least one line on this bill';
      }
      for (final id in cartItemIdsToMove) {
        if (!byId.containsKey(id)) return 'Invalid line selection';
      }

      final reserved = await orderRepo.createCartWithReservedInvoice(
        orderType: 'dine_in',
        deliveryPartner: null,
        branchId: source.branchId,
      );
      final newInvoice = reserved.invoice;
      final newCartId = reserved.cartId;
      await cartRepo.reassignCartItemsToCart(cartItemIdsToMove, newCartId);

      final moved = await cartRepo.getCartItemsByCartId(newCartId) ?? [];
      final movedTotal = _sumLineTotals(moved);

      var childHub = source.hubMetadata;
      final srcAnchor = DineInRefParser.dineInAnchorForMatching(source);
      if (srcAnchor != null && srcAnchor.isNotEmpty) {
        final fid = DineInRefParser.extractLeadingFloorId(srcAnchor) ?? 1;
        final tc = DineInRefParser.extractTableCode(srcAnchor);
        final childAnchor = DineInRefParser.buildTableOnlyReference(fid, tc);
        childHub = DineInRefParser.mergeHubMetadataAnchor(source.hubMetadata, childAnchor);
      }

      final newOrder = Order(
        id: 0,
        cartId: newCartId,
        invoiceNumber: newInvoice,
        referenceNumber: null,
        totalAmount: movedTotal,
        discountAmount: 0,
        discountType: null,
        finalAmount: movedTotal,
        customerName: source.customerName,
        customerEmail: source.customerEmail,
        customerPhone: source.customerPhone,
        customerGender: source.customerGender,
        customerAddress: source.customerAddress,
        cashAmount: 0,
        creditAmount: 0,
        cardAmount: 0,
        onlineAmount: 0,
        createdAt: DateTime.now(),
        status: source.status,
        orderType: 'dine_in',
        deliveryPartner: null,
        driverId: null,
        driverName: null,
        userId: source.userId,
        branchId: source.branchId,
        hubMetadata: childHub,
        hubSyncPending: false,
      );
      await orderRepo.createOrder(newOrder);

      await _syncOrderTotalsFromCart(source);
      await loadOrders();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Merge [sourceOrderId] into [targetOrderId] (same table reference). Sums payments; totals from lines.
  Future<String?> mergeDineInBill({
    required int targetOrderId,
    required int sourceOrderId,
  }) async {
    try {
      if (targetOrderId == sourceOrderId) return 'Choose a different bill';
      final target = await orderRepo.getOrderById(targetOrderId);
      final source = await orderRepo.getOrderById(sourceOrderId);
      if (target == null || source == null) return 'Order not found';
      if (!dineInBillIsSplittable(target) || !dineInBillIsSplittable(source)) {
        return 'Only open bills (KOT / placed) can be merged';
      }
      if (target.orderType != 'dine_in' || source.orderType != 'dine_in') {
        return 'Only dine-in bills can be merged';
      }
      final tRef = DineInRefParser.dineInAnchorForMatching(target)?.trim();
      final sRef = DineInRefParser.dineInAnchorForMatching(source)?.trim();
      if (tRef == null || tRef.isEmpty || sRef == null || sRef.isEmpty) {
        return 'Table assignment is missing for one of the bills';
      }
      if (!DineInRefParser.sameTableRouting(tRef, sRef)) {
        return 'Bills must be for the same table';
      }

      final sourceItems = await cartRepo.getCartItemsByCartId(source.cartId) ?? [];
      if (sourceItems.isEmpty) return 'Nothing to merge';

      await cartRepo.reassignCartItemsToCart(
        sourceItems.map((e) => e.id).toList(),
        target.cartId,
      );

      final mergedItems = await cartRepo.getCartItemsByCartId(target.cartId) ?? [];
      final total = _sumLineTotals(mergedItems);

      await orderRepo.updateOrder(
        target.copyWith(
          totalAmount: total,
          finalAmount: total,
          discountAmount: 0,
          discountType: const Value<String?>(null),
          cashAmount: target.cashAmount + source.cashAmount,
          creditAmount: target.creditAmount + source.creditAmount,
          cardAmount: target.cardAmount + source.cardAmount,
          onlineAmount: target.onlineAmount + source.onlineAmount,
        ),
      );

      await orderRepo.deleteOrder(sourceOrderId);
      await cartRepo.deleteCart(source.cartId);
      await loadOrders();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<void> close() {
    _detachHubLive?.call();
    return super.close();
  }
}
