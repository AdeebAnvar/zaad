import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';
import 'package:pos/data/repository/order_repository.dart';

part 'delivery_log_state.dart';

class DeliveryLogCubit extends Cubit<DeliveryLogState> {
  DeliveryLogCubit(this.orderRepo, this.deliveryPartnerRepo) : super(DeliveryLogInitial()) {
    loadOrders();
  }

  final OrderRepository orderRepo;
  final DeliveryPartnerRepository deliveryPartnerRepo;
  String? _selectedPartner;

  void selectPartnerTab(String? partner) {
    _selectedPartner = partner;
    if (partner == null) {
      loadOrders();
    } else {
      filterOrders(deliveryPartner: partner);
    }
  }

  Future<void> loadOrders() async {
    emit(DeliveryLogLoading());
    try {
      final partners = await deliveryPartnerRepo.getAll();
      var orders = await orderRepo.filterOrders(orderType: 'delivery');
      orders = orders.where((o) => o.status != 'cancelled').toList();
      emit(DeliveryLogLoaded(orders, _selectedPartner, partners));
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
      if (status == null || status.isEmpty || status == 'All') {
        orders = orders.where((o) => o.status != 'cancelled').toList();
      }
      emit(DeliveryLogLoaded(orders, _selectedPartner, partners));
    } catch (e) {
      emit(DeliveryLogError(e.toString()));
    }
  }

  Future<void> deleteOrder(int orderId) async {
    try {
      await orderRepo.deleteOrder(orderId);
      await loadOrders();
    } catch (e) {
      emit(DeliveryLogError(e.toString()));
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      await orderRepo.updateOrderStatus(orderId, status);
      await loadOrders();
    } catch (e) {
      emit(DeliveryLogError(e.toString()));
    }
  }

  Future<void> updateOrderPaymentType(int orderId, String paymentType, double finalAmount) async {
    try {
      final order = await orderRepo.getOrderById(orderId);
      if (order == null) return;
      final updated = order.copyWith(
        cashAmount: paymentType == 'CASH' ? finalAmount : 0,
        cardAmount: paymentType == 'CARD' ? finalAmount : 0,
        creditAmount: 0,
        onlineAmount: paymentType == 'ONLINE' ? finalAmount : 0,
      );
      await orderRepo.updateOrder(updated);
      await loadOrders();
    } catch (e) {
      emit(DeliveryLogError(e.toString()));
    }
  }
}
