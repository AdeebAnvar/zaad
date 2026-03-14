import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';

part 'delivery_log_state.dart';

class DeliveryLogCubit extends Cubit<DeliveryLogState> {
  DeliveryLogCubit(this.orderRepo) : super(DeliveryLogInitial()) {
    loadOrders();
  }

  final OrderRepository orderRepo;

  Future<void> loadOrders() async {
    emit(DeliveryLogLoading());
    try {
      var orders = await orderRepo.filterOrders(orderType: 'delivery');
      // Delivery Log = unpaid (kot) orders, similar to Take Away Log
      orders = orders.where((o) => o.status == 'kot').toList();
      emit(DeliveryLogLoaded(orders));
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
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    emit(DeliveryLogLoading());
    try {
      var orders = await orderRepo.filterOrders(
        invoiceNumber: invoiceNumber,
        referenceNumber: referenceNumber,
        orderType: 'delivery',
        deliveryPartner: deliveryPartner,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      if (status == null || status.isEmpty || status == 'All') {
        orders = orders.where((o) => o.status == 'kot').toList();
      }
      emit(DeliveryLogLoaded(orders));
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
}
