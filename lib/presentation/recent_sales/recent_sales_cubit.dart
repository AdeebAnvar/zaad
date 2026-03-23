import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';

part 'recent_sales_state.dart';

class RecentSalesCubit extends Cubit<RecentSalesState> {
  RecentSalesCubit(this.orderRepo) : super(RecentSalesInitial()) {
    loadOrders();
  }

  final OrderRepository orderRepo;

  Future<void> loadOrders() async {
    emit(RecentSalesLoading());
    try {
      // Recent Sales = paid orders only (completed). Exclude kot (unpaid, in Take Away Log)
      final allOrders = await orderRepo.getAllOrders();
      final filteredOrders = allOrders.where((order) => order.status == 'completed').toList();
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
  }) async {
    emit(RecentSalesLoading());
    try {
      // First filter by status, date, invoice, reference
      var orders = await orderRepo.filterOrders(
        invoiceNumber: invoiceNumber,
        referenceNumber: referenceNumber,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

      // Recent Sales = paid orders only. Show only completed (unless filter specifies otherwise)
      if (status == null || status.isEmpty || status == 'All') {
        orders = orders.where((order) => order.status == 'completed').toList();
      } else {
        orders = orders.where((order) => order.status != 'kot').toList();
      }

      // Filter by order type if specified (this would need to be inferred from cart/other fields)
      if (orderType != null && orderType.isNotEmpty) {
        // TODO: Implement order type filtering based on cart or other fields
        // For now, we'll skip this as order type is not stored directly
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
}
