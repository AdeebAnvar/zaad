import 'package:pos/data/models/pos_customer.dart';
import 'package:pos/domain/models/customer_model.dart';

abstract class CustomerRepository {
  // Server operations
  Future<List<CustomerModel>> fetchCustomersFromServer();

  // Local operations (rows align with [CustomerCreatedUpdated])
  Future<void> saveCustomersToLocal(List<CustomerModel> customers);
  Future<List<PosCustomer>> getAllLocalCustomers();
  Future<PosCustomer?> getCustomerById(int id);
  Future<List<PosCustomer>> searchCustomers(String query);
  Future<List<PosCustomer>> getCustomersByName(String name);
  Future<List<PosCustomer>> getCustomersByPhone(String phone);
  Future<List<PosCustomer>> getCustomersByEmail(String email);
  Future<int> saveCustomer(PosCustomer customer);
  Future<void> updateCustomer(PosCustomer customer);
  Future<List<PosCustomer>> getUnsyncedCustomers();
  Future<void> markAsSynced(int id);
}
