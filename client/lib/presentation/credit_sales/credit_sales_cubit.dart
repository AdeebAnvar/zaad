import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/utils/hub_log_order_user_scope.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';

part 'credit_sales_state.dart';

class CreditSalesCubit extends Cubit<CreditSalesState> {
  CreditSalesCubit(
    this.orderRepo,
    this.hubSettings,
    this.counterSession,
  ) : super(CreditSalesInitial()) {
    load();
  }

  final OrderRepository orderRepo;
  final LocalHubSettings hubSettings;
  final CurrentCounterSession counterSession;
  List<Order> _all = [];
  String _filterQuery = '';

  Future<void> load() async {
    emit(CreditSalesLoading());
    try {
      // Branch receivables — all staff with Credit Sales access see the same list.
      _all = await orderRepo.getCreditSales(
        userId: HubLogOrderUserScope.effectiveFilterUserId(
          hub: hubSettings,
          sessionUser: counterSession.user,
          sharedBranchLogsOnSub: true,
        ),
      );
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
    sortOrdersNewestFirst(filtered);
    emit(CreditSalesLoaded(filteredOrders: filtered, filterQuery: _filterQuery));
  }

  Future<void> refresh() => load();
}
