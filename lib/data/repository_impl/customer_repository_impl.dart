import 'package:drift/drift.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/models/pos_customer.dart';
import 'package:pos/data/repository/customer_repository.dart';
import 'package:pos/domain/models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final AppDatabase db;
  String serverUrl = "";

  CustomerRepositoryImpl(this.db);

  // ---------------- SERVER (DUMMY) ----------------

  @override
  Future<List<CustomerModel>> fetchCustomersFromServer() async {
    if (!serverUrl.startsWith("adibzz")) {
      throw Exception("Invalid Server URL");
    }

    await Future.delayed(const Duration(seconds: 1));

    // Dummy customer data from server
    return [];
  }

  // ---------------- SAVE TO LOCAL ----------------

  @override
  Future<void> saveCustomersToLocal(List<CustomerModel> customers) async {
    for (final page in customers) {
      for (final c in page.createdUpdated) {
        final serverKey = c.id.toString();
        final existing = await db.customersDao.getCustomerByServerId(serverKey);
        final phone = c.customerNumber.isNotEmpty ? c.customerNumber : null;
        if (existing == null) {
          await db.customersDao.insertOrUpdateCustomer(
            CustomersCompanion.insert(
              serverId: Value(serverKey),
              recordUuid: Value(c.uuid),
              branchId: Value(c.branchId),
              customerNumber: Value(c.customerNumber),
              name: c.customerName,
              email: Value(c.customerEmail.isNotEmpty ? c.customerEmail : null),
              phone: Value(phone),
              gender: Value(c.customerGender.isNotEmpty ? c.customerGender : null),
              address: Value(c.customerAddress.isNotEmpty ? c.customerAddress : null),
              cardNo: Value(c.cardNo.isNotEmpty ? c.cardNo : null),
              createdAt: Value(c.createdAt),
              updatedAt: Value(c.updatedAt),
              isSynced: const Value(true),
            ),
          );
        } else {
          await db.customersDao.updateCustomer(
            CustomersCompanion(
              id: Value(existing.id),
              serverId: Value(serverKey),
              recordUuid: Value(c.uuid),
              branchId: Value(c.branchId),
              customerNumber: Value(c.customerNumber),
              name: Value(c.customerName),
              email: Value(c.customerEmail.isNotEmpty ? c.customerEmail : null),
              phone: Value(phone),
              gender: Value(c.customerGender.isNotEmpty ? c.customerGender : null),
              address: Value(c.customerAddress.isNotEmpty ? c.customerAddress : null),
              cardNo: Value(c.cardNo.isNotEmpty ? c.cardNo : null),
              updatedAt: Value(DateTime.now()),
              isSynced: const Value(true),
            ),
          );
        }
      }
    }
  }

  // ---------------- LOCAL OPERATIONS ----------------

  @override
  Future<List<PosCustomer>> getAllLocalCustomers() async {
    final customers = await db.customersDao.getAllCustomers();
    return customers.map(PosCustomer.fromDrift).toList();
  }

  @override
  Future<PosCustomer?> getCustomerById(int id) async {
    final customer = await db.customersDao.getCustomerById(id);
    return customer != null ? PosCustomer.fromDrift(customer) : null;
  }

  @override
  Future<List<PosCustomer>> searchCustomers(String query) async {
    final customers = await db.customersDao.searchCustomers(query);
    return customers.map(PosCustomer.fromDrift).toList();
  }

  @override
  Future<List<PosCustomer>> getCustomersByName(String name) async {
    final customers = await db.customersDao.getCustomersByName(name);
    return customers.map(PosCustomer.fromDrift).toList();
  }

  @override
  Future<List<PosCustomer>> getCustomersByPhone(String phone) async {
    final customers = await db.customersDao.getCustomersByPhone(phone);
    return customers.map(PosCustomer.fromDrift).toList();
  }

  @override
  Future<List<PosCustomer>> getCustomersByEmail(String email) async {
    final customers = await db.customersDao.getCustomersByEmail(email);
    return customers.map(PosCustomer.fromDrift).toList();
  }

  @override
  Future<int> saveCustomer(PosCustomer customer) async {
    if (customer.localId > 0) {
      throw StateError('Use updateCustomer for existing rows');
    }
    return db.customersDao.insertCustomer(
      CustomersCompanion.insert(
        serverId: customer.serverIdStr != null ? Value(customer.serverIdStr) : const Value.absent(),
        recordUuid: Value(customer.row.uuid),
        branchId: Value(customer.row.branchId),
        customerNumber: Value(customer.row.customerNumber.isNotEmpty ? customer.row.customerNumber : null),
        name: customer.row.customerName,
        email: Value(customer.row.customerEmail.isNotEmpty ? customer.row.customerEmail : null),
        phone: Value(customer.row.customerNumber.isNotEmpty ? customer.row.customerNumber : null),
        gender: Value(customer.row.customerGender.isNotEmpty ? customer.row.customerGender : null),
        address: Value(customer.row.customerAddress.isNotEmpty ? customer.row.customerAddress : null),
        cardNo: Value(customer.row.cardNo.isNotEmpty ? customer.row.cardNo : null),
        createdAt: Value(customer.row.createdAt),
        updatedAt: Value(customer.row.updatedAt),
        isSynced: Value(customer.isSynced),
      ),
    );
  }

  @override
  Future<void> updateCustomer(PosCustomer customer) {
    if (customer.localId <= 0) return Future.value();
    return db.customersDao.updateCustomer(
      CustomersCompanion(
        id: Value(customer.localId),
        serverId: customer.serverIdStr != null ? Value(customer.serverIdStr) : const Value.absent(),
        recordUuid: Value(customer.row.uuid),
        branchId: Value(customer.row.branchId),
        customerNumber: Value(customer.row.customerNumber.isNotEmpty ? customer.row.customerNumber : null),
        name: Value(customer.row.customerName),
        email: Value(customer.row.customerEmail.isNotEmpty ? customer.row.customerEmail : null),
        phone: Value(customer.row.customerNumber.isNotEmpty ? customer.row.customerNumber : null),
        gender: Value(customer.row.customerGender.isNotEmpty ? customer.row.customerGender : null),
        address: Value(customer.row.customerAddress.isNotEmpty ? customer.row.customerAddress : null),
        cardNo: Value(customer.row.cardNo.isNotEmpty ? customer.row.cardNo : null),
        updatedAt: Value(DateTime.now()),
        isSynced: Value(customer.isSynced),
      ),
    );
  }

  @override
  Future<List<PosCustomer>> getUnsyncedCustomers() async {
    final customers = await db.customersDao.getUnsyncedCustomers();
    return customers.map(PosCustomer.fromDrift).toList();
  }

  @override
  Future<void> markAsSynced(int id) async {
    await db.customersDao.markAsSynced(id);
  }
}
