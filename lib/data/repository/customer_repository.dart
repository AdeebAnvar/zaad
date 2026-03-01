import '../../domain/models/customer_model.dart';

abstract class CustomerRepository {
  // Server operations
  Future<List<CustomerModel>> fetchCustomersFromServer();
  
  // Local operations
  Future<void> saveCustomersToLocal(List<CustomerModel> customers);
  Future<List<CustomerModel>> getAllLocalCustomers();
  Future<CustomerModel?> getCustomerById(int id);
  Future<List<CustomerModel>> searchCustomers(String query);
  Future<List<CustomerModel>> getCustomersByName(String name);
  Future<List<CustomerModel>> getCustomersByPhone(String phone);
  Future<List<CustomerModel>> getCustomersByEmail(String email);
  Future<int> saveCustomer(CustomerModel customer);
  Future<void> updateCustomer(CustomerModel customer);
  Future<List<CustomerModel>> getUnsyncedCustomers();
  Future<void> markAsSynced(int id);
  
  void setServerUrl(String url);
}
