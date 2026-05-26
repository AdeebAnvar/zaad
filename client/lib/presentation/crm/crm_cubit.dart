import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/utils/order_display_utils.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/models/pos_customer.dart';
import 'package:pos/data/repository/customer_repository.dart';

part 'crm_state.dart';

// ── isolate-safe payload (no DB objects cross isolate boundary) ──────────────

class _MatchPayload {
  const _MatchPayload({required this.customers, required this.orders});
  final List<PosCustomer> customers;
  final List<Order> orders;
}

bool _orderMatchesCustomer(Order order, PosCustomer customer) {
  final r = customer.row;
  final pCust = normalizePhoneDigits(
    r.customerNumber.isNotEmpty ? r.customerNumber : null,
  );
  final pOrder = normalizePhoneDigits(order.customerPhone);
  if (pCust != null && pCust.isNotEmpty && pOrder != null && pOrder == pCust) {
    return true;
  }
  if (r.customerEmail.isNotEmpty &&
      (order.customerEmail?.trim().toLowerCase() ==
          r.customerEmail.trim().toLowerCase())) {
    return true;
  }
  if (r.customerName.isNotEmpty &&
      (order.customerName?.trim().toLowerCase() ==
          r.customerName.trim().toLowerCase())) {
    return true;
  }
  return false;
}

/// Runs the O(N×M) customer–order join off the UI isolate.
List<CustomerWithOrders> _buildCustomerWithOrders(_MatchPayload payload) {
  final result = <CustomerWithOrders>[];
  for (final customer in payload.customers) {
    final orders = payload.orders
        .where((order) => _orderMatchesCustomer(order, customer))
        .toList();
    result.add(CustomerWithOrders(
      customer: customer,
      orderCount: orders.length,
      totalSpent:
          orders.fold<double>(0.0, (sum, o) => sum + o.finalAmount),
      lastOrderDate: orders.isNotEmpty ? orders.first.createdAt : null,
    ));
  }
  return result;
}

// ── cubit ────────────────────────────────────────────────────────────────────

class CrmCubit extends Cubit<CrmState> {
  final CustomerRepository _customerRepo;
  final AppDatabase _db;

  CrmCubit(this._customerRepo, this._db) : super(CrmInitial());

  Future<List<Order>> _ordersForActiveBranch() async {
    final session = await _db.sessionDao.getActiveSession();
    final branchId = session?.branchId ?? 1;
    return _db.ordersDao.getAllOrders(branchId: branchId);
  }

  Future<void> loadCustomers() async {
    emit(CrmLoading());
    try {
      final customers = await _customerRepo.getAllLocalCustomers();
      final allOrders = await _ordersForActiveBranch();
      final customersWithOrders = await compute(
        _buildCustomerWithOrders,
        _MatchPayload(customers: customers, orders: allOrders),
      );
      emit(CrmLoaded(customersWithOrders));
    } catch (e) {
      emit(CrmError(e.toString()));
    }
  }

  Future<void> searchCustomers(String query) async {
    if (query.isEmpty) {
      await loadCustomers();
      return;
    }
    emit(CrmLoading());
    try {
      final customers = await _customerRepo.searchCustomers(query);
      final allOrders = await _ordersForActiveBranch();
      final customersWithOrders = await compute(
        _buildCustomerWithOrders,
        _MatchPayload(customers: customers, orders: allOrders),
      );
      emit(CrmLoaded(customersWithOrders));
    } catch (e) {
      emit(CrmError(e.toString()));
    }
  }

  Future<void> filterCustomers({
    String? name,
    String? phone,
    String? email,
  }) async {
    emit(CrmLoading());
    try {
      final List<PosCustomer> customers;
      if (name != null && name.isNotEmpty) {
        customers = await _customerRepo.getCustomersByName(name);
      } else if (phone != null && phone.isNotEmpty) {
        customers = await _customerRepo.getCustomersByPhone(phone);
      } else if (email != null && email.isNotEmpty) {
        customers = await _customerRepo.getCustomersByEmail(email);
      } else {
        customers = await _customerRepo.getAllLocalCustomers();
      }

      final session = await _db.sessionDao.getActiveSession();
      final branchId = session?.branchId ?? 1;
      final allOrders = await _db.ordersDao.getAllOrders(branchId: branchId);
      final customersWithOrders = await compute(
        _buildCustomerWithOrders,
        _MatchPayload(customers: customers, orders: allOrders),
      );
      emit(CrmLoaded(customersWithOrders));
    } catch (e) {
      emit(CrmError(e.toString()));
    }
  }

  Future<List<Order>> getCustomerOrders(int customerId) async {
    final customer = await _customerRepo.getCustomerById(customerId);
    if (customer == null) return [];
    final allOrders = await _ordersForActiveBranch();
    final list = await compute(
      _matchOrdersForCustomer,
      _SingleCustomerPayload(customer: customer, orders: allOrders),
    );
    return list;
  }
}

class _SingleCustomerPayload {
  const _SingleCustomerPayload(
      {required this.customer, required this.orders});
  final PosCustomer customer;
  final List<Order> orders;
}

List<Order> _matchOrdersForCustomer(_SingleCustomerPayload p) {
  final list =
      p.orders.where((o) => _orderMatchesCustomer(o, p.customer)).toList();
  sortOrdersNewestFirst(list);
  return list;
}

class CustomerWithOrders {
  final PosCustomer customer;
  final int orderCount;
  final double totalSpent;
  final DateTime? lastOrderDate;

  CustomerWithOrders({
    required this.customer,
    required this.orderCount,
    required this.totalSpent,
    this.lastOrderDate,
  });
}
