import 'package:drift/drift.dart';
import '../../domain/models/customer_model.dart';
import '../repository/customer_repository.dart';
import '../local/drift_database.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final AppDatabase db;
  String serverUrl = "";

  CustomerRepositoryImpl(this.db);

  @override
  void setServerUrl(String url) {
    serverUrl = url;
  }

  // ---------------- SERVER (DUMMY) ----------------

  @override
  Future<List<CustomerModel>> fetchCustomersFromServer() async {
    if (!serverUrl.startsWith("adibzz")) {
      throw Exception("Invalid Server URL");
    }

    await Future.delayed(const Duration(seconds: 1));

    // Dummy customer data from server
    return [
      CustomerModel(
        serverId: "1",
        name: "John Doe",
        email: "john@example.com",
        phone: "1234567890",
        gender: "Male",
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isSynced: true,
      ),
      CustomerModel(
        serverId: "2",
        name: "Jane Smith",
        email: "jane@example.com",
        phone: "9876543210",
        gender: "Female",
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isSynced: true,
      ),
      CustomerModel(
        serverId: "3",
        name: "Robert Johnson",
        email: "robert@example.com",
        phone: "5551234567",
        gender: "Male",
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        isSynced: true,
      ),
    ];
  }

  // ---------------- SAVE TO LOCAL ----------------

  @override
  Future<void> saveCustomersToLocal(List<CustomerModel> customers) async {
    for (final customer in customers) {
      final existing = await db.customersDao.getCustomerByServerId(customer.serverId ?? "");
      if (existing == null) {
        await db.customersDao.insertOrUpdateCustomer(
          CustomersCompanion.insert(
            serverId: Value(customer.serverId),
            name: customer.name,
            email: Value(customer.email),
            phone: Value(customer.phone),
            gender: Value(customer.gender),
            createdAt: Value(customer.createdAt ?? DateTime.now()),
            updatedAt: Value(customer.updatedAt ?? DateTime.now()),
            isSynced: const Value(true),
          ),
        );
      } else {
        await db.customersDao.updateCustomer(
          CustomersCompanion(
            id: Value(existing.id),
            serverId: Value(customer.serverId),
            name: Value(customer.name),
            email: Value(customer.email),
            phone: Value(customer.phone),
            gender: Value(customer.gender),
            updatedAt: Value(DateTime.now()),
            isSynced: const Value(true),
          ),
        );
      }
    }
  }

  // ---------------- LOCAL OPERATIONS ----------------

  @override
  Future<List<CustomerModel>> getAllLocalCustomers() async {
    final customers = await db.customersDao.getAllCustomers();
    return customers.map(_mapToModel).toList();
  }

  @override
  Future<CustomerModel?> getCustomerById(int id) async {
    final customer = await db.customersDao.getCustomerById(id);
    return customer != null ? _mapToModel(customer) : null;
  }

  @override
  Future<List<CustomerModel>> searchCustomers(String query) async {
    final customers = await db.customersDao.searchCustomers(query);
    return customers.map(_mapToModel).toList();
  }

  @override
  Future<List<CustomerModel>> getCustomersByName(String name) async {
    final customers = await db.customersDao.getCustomersByName(name);
    return customers.map(_mapToModel).toList();
  }

  @override
  Future<List<CustomerModel>> getCustomersByPhone(String phone) async {
    final customers = await db.customersDao.getCustomersByPhone(phone);
    return customers.map(_mapToModel).toList();
  }

  @override
  Future<List<CustomerModel>> getCustomersByEmail(String email) async {
    final customers = await db.customersDao.getCustomersByEmail(email);
    return customers.map(_mapToModel).toList();
  }

  @override
  Future<int> saveCustomer(CustomerModel customer) async {
    return await db.customersDao.insertCustomer(
      CustomersCompanion.insert(
        serverId: Value(customer.serverId),
        name: customer.name,
        email: Value(customer.email),
        phone: Value(customer.phone),
        gender: Value(customer.gender),
        createdAt: Value(customer.createdAt ?? DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isSynced: Value(customer.isSynced),
      ),
    );
  }

  @override
  Future<void> updateCustomer(CustomerModel customer) async {
    if (customer.id == null) return;
    await db.customersDao.updateCustomer(
      CustomersCompanion(
        id: Value(customer.id!),
        serverId: Value(customer.serverId),
        name: Value(customer.name),
        email: Value(customer.email),
        phone: Value(customer.phone),
        gender: Value(customer.gender),
        updatedAt: Value(DateTime.now()),
        isSynced: Value(customer.isSynced),
      ),
    );
  }

  @override
  Future<List<CustomerModel>> getUnsyncedCustomers() async {
    final customers = await db.customersDao.getUnsyncedCustomers();
    return customers.map(_mapToModel).toList();
  }

  @override
  Future<void> markAsSynced(int id) async {
    await db.customersDao.markAsSynced(id);
  }

  // ---------------- MAPPERS ----------------

  CustomerModel _mapToModel(Customer customer) {
    return CustomerModel(
      id: customer.id,
      serverId: customer.serverId,
      name: customer.name,
      email: customer.email,
      phone: customer.phone,
      gender: customer.gender,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
      isSynced: customer.isSynced,
    );
  }
}
