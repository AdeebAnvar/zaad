import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';

part 'take_away_log_state.dart';

class TakeAwayLogCubit extends Cubit<TakeAwayLogState> {
  TakeAwayLogCubit(this.orderRepo) : super(TakeAwayLogInitial()) {
    loadOrders();
  }

  final OrderRepository orderRepo;

  Future<void> loadOrders() async {
    emit(TakeAwayLogLoading());
    try {
      final orders = await orderRepo.getAllOrders();
      // Take Away Log = unpaid orders waiting for items. Only show kot (exclude completed, placed)
      final filteredOrders = orders.where((order) => order.status == 'kot').toList();
      emit(TakeAwayLogLoaded(filteredOrders));
    } catch (e) {
      emit(TakeAwayLogError(e.toString()));
    }
  }

  Future<void> refreshOrders() async {
    await loadOrders();
  }

  Future<void> filterOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    emit(TakeAwayLogLoading());
    try {
      var orders = await orderRepo.filterOrders(
        invoiceNumber: invoiceNumber,
        referenceNumber: referenceNumber,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      // Take Away Log = unpaid only. Show kot; if status filter specified, respect it but exclude completed
      if (status == null || status.isEmpty || status == 'All') {
        orders = orders.where((order) => order.status == 'kot').toList();
      } else if (status != 'completed') {
        orders = orders.where((order) => order.status != 'completed').toList();
      } else {
        orders = []; // Never show completed in Take Away Log
      }
      emit(TakeAwayLogLoaded(orders));
    } catch (e) {
      emit(TakeAwayLogError(e.toString()));
    }
  }

  Future<void> deleteOrder(int orderId) async {
    try {
      await orderRepo.deleteOrder(orderId);
      await loadOrders(); // Reload orders after deletion
    } catch (e) {
      emit(TakeAwayLogError(e.toString()));
    }
  }
}
