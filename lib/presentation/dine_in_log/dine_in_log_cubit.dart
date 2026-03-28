import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';

part 'dine_in_log_state.dart';

class DineInLogCubit extends Cubit<DineInLogState> {
  DineInLogCubit(this.orderRepo) : super(DineInLogInitial()) {
    loadOrders();
  }

  final OrderRepository orderRepo;

  Future<void> loadOrders() async {
    emit(DineInLogLoading());
    try {
      final orders = await orderRepo.filterOrders(orderType: 'dine_in');
      // Show KOT + paid + other active; exclude cancelled (same idea as floor + history).
      final visible = orders.where((o) => o.status != 'cancelled').toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(DineInLogLoaded(visible));
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
      emit(DineInLogLoaded(orders));
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
}
