import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';

part 'credit_sales_state.dart';

class CreditSalesCubit extends Cubit<CreditSalesState> {
  CreditSalesCubit(this.orderRepo) : super(CreditSalesInitial()) {
    load();
  }

  final OrderRepository orderRepo;
  List<Order> _all = [];
  String _filterQuery = '';

  Future<void> load() async {
    emit(CreditSalesLoading());
    try {
      _all = await orderRepo.getCreditSales();
      _emitLoaded();
    } catch (e) {
      emit(CreditSalesError(e.toString()));
    }
  }

  void setCustomerFilter(String query) {
    _filterQuery = query;
    if (_all.isNotEmpty || state is CreditSalesLoaded) {
      _emitLoaded();
    }
  }

  void _emitLoaded() {
    final q = _filterQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? List<Order>.from(_all)
        : _all.where((o) {
            final name = (o.customerName ?? '').toLowerCase();
            final phone = (o.customerPhone ?? '').toLowerCase();
            return name.contains(q) || phone.contains(q);
          }).toList();
    emit(CreditSalesLoaded(filteredOrders: filtered, filterQuery: _filterQuery));
  }

  Future<void> refresh() => load();
}
