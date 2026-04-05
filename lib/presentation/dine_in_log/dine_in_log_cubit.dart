import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/order_repository.dart';

part 'dine_in_log_state.dart';

bool dineInBillIsSplittable(Order order) {
  final s = order.status.toLowerCase();
  return order.orderType == 'dine_in' && (s == 'kot' || s == 'placed');
}

class DineInLogCubit extends Cubit<DineInLogState> {
  DineInLogCubit(this.orderRepo, this.cartRepo) : super(DineInLogInitial()) {
    loadOrders();
  }

  final OrderRepository orderRepo;
  final CartRepository cartRepo;

  Future<void> loadOrders() async {
    emit(DineInLogLoading());
    try {
      final orders = await orderRepo.filterOrders(orderType: 'dine_in');
      // Show KOT + paid + other active; exclude cancelled (same idea as floor + history).
      final visible = orders.where((o) => o.status != 'cancelled').toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final cartIds = visible.map((o) => o.cartId).toSet().toList();
      final counts = await cartRepo.countCartItemsByCartIds(cartIds);
      emit(DineInLogLoaded(visible, counts));
    } catch (e) {
      emit(DineInLogError(e.toString()));
    }
  }

  Future<void> refreshOrders() async => loadOrders();

  Future<void> filterOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    emit(DineInLogLoading());
    try {
      var orders = await orderRepo.filterOrders(
        invoiceNumber: invoiceNumber,
        referenceNumber: referenceNumber,
        status: status,
        orderType: 'dine_in',
        startDate: startDate,
        endDate: endDate,
      );
      if (status == null || status.isEmpty || status == 'All') {
        orders = orders.where((o) => o.status != 'cancelled').toList();
      } else {
        orders = orders.where((o) => o.status == status).toList();
      }
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final cartIds = orders.map((o) => o.cartId).toSet().toList();
      final counts = await cartRepo.countCartItemsByCartIds(cartIds);
      emit(DineInLogLoaded(orders, counts));
    } catch (e) {
      emit(DineInLogError(e.toString()));
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

  /// Updates dine-in table/floor reference (`floorId|CODE | N pax`). Returns null on success.
  Future<String?> moveDineInOrderToTable({
    required int orderId,
    required String newReferenceNumber,
  }) async {
    try {
      final order = await orderRepo.getOrderById(orderId);
      if (order == null) return 'Order not found';
      await orderRepo.updateOrder(
        order.copyWith(referenceNumber: Value(newReferenceNumber)),
      );
      await loadOrders();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  double _sumLineTotals(List<CartItem> items) =>
      items.fold<double>(0, (sum, e) => sum + e.total);

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

      final newInvoice = await orderRepo.getNextInvoiceNumber('dine_in');
      final newCartId = await cartRepo.createCart(newInvoice, orderType: 'dine_in');
      await cartRepo.reassignCartItemsToCart(cartItemIdsToMove, newCartId);

      final moved = await cartRepo.getCartItemsByCartId(newCartId) ?? [];
      final movedTotal = _sumLineTotals(moved);

      final newOrder = Order(
        id: 0,
        cartId: newCartId,
        invoiceNumber: newInvoice,
        referenceNumber: source.referenceNumber,
        totalAmount: movedTotal,
        discountAmount: 0,
        discountType: null,
        finalAmount: movedTotal,
        customerName: source.customerName,
        customerEmail: source.customerEmail,
        customerPhone: source.customerPhone,
        customerGender: source.customerGender,
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
      final tRef = target.referenceNumber?.trim();
      final sRef = source.referenceNumber?.trim();
      if (tRef == null || tRef.isEmpty || tRef != sRef) {
        return 'Bills must be for the same table / reference';
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
}
