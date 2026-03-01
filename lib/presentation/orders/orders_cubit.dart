import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';

part 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this.orderRepo) : super(OrdersInitial());

  final OrderRepository orderRepo;

  Future<void> loadOrders() async {
    emit(OrdersLoading());
    try {
      final orders = await orderRepo.getAllOrders();
      // Filter only completed orders
      final completedOrders = orders.where((o) => o.status == 'completed').toList();
      emit(OrdersLoaded(completedOrders));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }
}
