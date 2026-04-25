import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';
import 'package:pos/data/repository/driver_repository.dart';
import 'package:pos/data/repository/order_repository.dart';

part 'delivery_log_state.dart';

/// Swiggy-style partners (not own fleet `NORMAL`): hide from delivery log once dispatched or cancelled.
bool _isPartnerDelivery(Order o) {
  final p = o.deliveryPartner?.trim().toUpperCase();
  if (p == null || p.isEmpty) return false;
  return p != 'NORMAL';
}

List<Order> _filterDeliveryLogList(List<Order> orders) {
  return orders.where((o) {
    final s = o.status.toLowerCase();
    if (s == 'cancelled') return false;
    if (_isPartnerDelivery(o) && s == 'dispatched') return false;
    return true;
  }).toList();
}

bool _isNormalOrder(Order o) => o.deliveryPartner?.trim().toUpperCase() == 'NORMAL';

bool _hasDriver(Order o) => o.driverId != null && (o.driverName?.trim().isNotEmpty ?? false);

class DeliveryLogCubit extends Cubit<DeliveryLogState> {
  DeliveryLogCubit(
    this.orderRepo,
    this.deliveryPartnerRepo,
    this.driverRepo,
  ) : super(DeliveryLogInitial()) {
    loadOrders();
  }

  final OrderRepository orderRepo;
  final DeliveryPartnerRepository deliveryPartnerRepo;
  final DriverRepository driverRepo;
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
      filterOrders(deliveryPartner: partner);
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
    try {
      final partners = await deliveryPartnerRepo.getAll();
      final drivers = await driverRepo.getAll();
      final partnerFilter = _selectedPartner?.trim();
      var orders = await orderRepo.filterOrders(
        orderType: 'delivery',
        deliveryPartner: partnerFilter != null && partnerFilter.isNotEmpty ? partnerFilter : null,
      );
      orders = _filterDeliveryLogList(orders);
      _normalSelection.removeWhere((id) => !orders.any((o) => o.id == id));
      emit(DeliveryLogLoaded(
        orders,
        _selectedPartner,
        partners,
        drivers,
        Set<int>.from(_normalSelection),
      ));
    } catch (e) {
      emit(DeliveryLogError(e.toString()));
    }
  }

  Future<void> refreshOrders() async {
    await loadOrders();
  }

  Future<void> filterOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? deliveryPartner,
    String? customerPhone,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _selectedPartner = deliveryPartner;
    emit(DeliveryLogLoading());
    try {
      final partners = await deliveryPartnerRepo.getAll();
      final drivers = await driverRepo.getAll();
      var orders = await orderRepo.filterOrders(
        invoiceNumber: invoiceNumber,
        referenceNumber: referenceNumber,
        orderType: 'delivery',
        deliveryPartner: deliveryPartner,
        customerPhone: customerPhone,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      orders = _filterDeliveryLogList(orders);
      _normalSelection.removeWhere((id) => !orders.any((o) => o.id == id));
      emit(DeliveryLogLoaded(
        orders,
        _selectedPartner,
        partners,
        drivers,
        Set<int>.from(_normalSelection),
      ));
    } catch (e) {
      emit(DeliveryLogError(e.toString()));
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
      if ((s == 'assigned' || s == 'delivered') && !_hasDriver(order)) {
        return 'Assign a driver before setting status to Assigned or Delivered.';
      }
      if (s == 'pending' && order.status.toLowerCase() == 'assigned') {
        return 'Cannot change status back to Pending after a driver is assigned.';
      }
    }
    try {
      await orderRepo.updateOrderStatus(orderId, newStatus);
      await loadOrders();
      return null;
    } catch (e) {
      emit(DeliveryLogError(e.toString()));
      return e.toString();
    }
  }

  /// Assign driver and set status to [assigned] for Normal delivery orders. Returns error message or null.
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
            status: 'assigned',
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
      final updated = order.copyWith(
        cashAmount: paymentType == 'CASH' ? finalAmount : 0,
        cardAmount: paymentType == 'CARD' ? finalAmount : 0,
        creditAmount: paymentType == 'CREDIT' ? finalAmount : 0,
        onlineAmount: paymentType == 'ONLINE' ? finalAmount : 0,
      );
      await orderRepo.updateOrder(updated);
      await loadOrders();
    } catch (e) {
      emit(DeliveryLogError(e.toString()));
    }
  }
}
