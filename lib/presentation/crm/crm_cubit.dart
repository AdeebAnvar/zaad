import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/data/repository/customer_repository.dart';
import 'package:pos/domain/models/customer_model.dart';
import 'package:pos/data/local/drift_database.dart';

part 'crm_state.dart';

class CrmCubit extends Cubit<CrmState> {
  final CustomerRepository _customerRepo;
  final AppDatabase _db;

  CrmCubit(this._customerRepo, this._db) : super(CrmInitial());

  Future<void> loadCustomers() async {
    emit(CrmLoading());
    try {
      final customers = await _customerRepo.getAllLocalCustomers();
      final customersWithOrders = <CustomerWithOrders>[];

      for (final customer in customers) {
        // Get all orders and filter by customer
        final allOrders = await _db.ordersDao.getAllOrders();
        final orders = allOrders.where((order) =>
          (customer.name.isNotEmpty && order.customerName?.toLowerCase() == customer.name.toLowerCase()) ||
          (customer.phone != null && customer.phone!.isNotEmpty && order.customerPhone == customer.phone) ||
          (customer.email != null && customer.email!.isNotEmpty && order.customerEmail?.toLowerCase() == customer.email?.toLowerCase())
        ).toList();

        customersWithOrders.add(CustomerWithOrders(
          customer: customer,
          orderCount: orders.length,
          totalSpent: orders.fold<double>(0.0, (sum, order) => sum + order.finalAmount),
          lastOrderDate: orders.isNotEmpty ? orders.first.createdAt : null,
        ));
      }

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
      final customersWithOrders = <CustomerWithOrders>[];

      for (final customer in customers) {
        // Get all orders and filter by customer
        final allOrders = await _db.ordersDao.getAllOrders();
        final orders = allOrders.where((order) =>
          (customer.name.isNotEmpty && order.customerName?.toLowerCase() == customer.name.toLowerCase()) ||
          (customer.phone != null && customer.phone!.isNotEmpty && order.customerPhone == customer.phone) ||
          (customer.email != null && customer.email!.isNotEmpty && order.customerEmail?.toLowerCase() == customer.email?.toLowerCase())
        ).toList();

        customersWithOrders.add(CustomerWithOrders(
          customer: customer,
          orderCount: orders.length,
          totalSpent: orders.fold<double>(0.0, (sum, order) => sum + order.finalAmount),
          lastOrderDate: orders.isNotEmpty ? orders.first.createdAt : null,
        ));
      }

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
      List<CustomerModel> customers = [];

      if (name != null && name.isNotEmpty) {
        customers = await _customerRepo.getCustomersByName(name);
      } else if (phone != null && phone.isNotEmpty) {
        customers = await _customerRepo.getCustomersByPhone(phone);
      } else if (email != null && email.isNotEmpty) {
        customers = await _customerRepo.getCustomersByEmail(email);
      } else {
        customers = await _customerRepo.getAllLocalCustomers();
      }

      final customersWithOrders = <CustomerWithOrders>[];

      for (final customer in customers) {
        // Get all orders and filter by customer
        final allOrders = await _db.ordersDao.getAllOrders();
        final orders = allOrders.where((order) =>
          (customer.name.isNotEmpty && order.customerName?.toLowerCase() == customer.name.toLowerCase()) ||
          (customer.phone != null && customer.phone!.isNotEmpty && order.customerPhone == customer.phone) ||
          (customer.email != null && customer.email!.isNotEmpty && order.customerEmail?.toLowerCase() == customer.email?.toLowerCase())
        ).toList();

        customersWithOrders.add(CustomerWithOrders(
          customer: customer,
          orderCount: orders.length,
          totalSpent: orders.fold<double>(0.0, (sum, order) => sum + order.finalAmount),
          lastOrderDate: orders.isNotEmpty ? orders.first.createdAt : null,
        ));
      }

      emit(CrmLoaded(customersWithOrders));
    } catch (e) {
      emit(CrmError(e.toString()));
    }
  }

  Future<List<Order>> getCustomerOrders(int customerId) async {
    final customer = await _customerRepo.getCustomerById(customerId);
    if (customer == null) return [];

    // Get all orders and filter by customer
    final allOrders = await _db.ordersDao.getAllOrders();
    return allOrders.where((order) =>
      (customer.name.isNotEmpty && order.customerName?.toLowerCase() == customer.name.toLowerCase()) ||
      (customer.phone != null && customer.phone!.isNotEmpty && order.customerPhone == customer.phone) ||
      (customer.email != null && customer.email!.isNotEmpty && order.customerEmail?.toLowerCase() == customer.email?.toLowerCase())
    ).toList();
  }
}

class CustomerWithOrders {
  final CustomerModel customer;
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
