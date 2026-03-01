part of '../drift_database.dart';

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get gender => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

@DriftAccessor(tables: [Customers])
class CustomersDao extends DatabaseAccessor<AppDatabase> with _$CustomersDaoMixin {
  CustomersDao(AppDatabase db) : super(db);

  /* ───────── CUSTOMERS ───────── */

  Future<int> insertCustomer(CustomersCompanion customer) {
    return into(customers).insert(customer);
  }

  Future<void> insertOrUpdateCustomer(CustomersCompanion customer) async {
    await into(customers).insertOnConflictUpdate(customer);
  }

  Future<List<Customer>> getAllCustomers() {
    return (select(customers)..orderBy([(c) => OrderingTerm.desc(c.createdAt)])).get();
  }

  Future<Customer?> getCustomerById(int id) {
    return (select(customers)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  Future<Customer?> getCustomerByServerId(String serverId) {
    return (select(customers)..where((c) => c.serverId.equals(serverId))).getSingleOrNull();
  }

  Future<List<Customer>> searchCustomers(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(customers)
          ..where((c) => 
            c.name.lower().contains(lowerQuery) |
            c.email.lower().contains(lowerQuery) |
            c.phone.contains(query)
          )
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  Future<List<Customer>> getCustomersByName(String name) {
    return (select(customers)
          ..where((c) => c.name.lower().equals(name.toLowerCase()))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  Future<List<Customer>> getCustomersByPhone(String phone) {
    return (select(customers)
          ..where((c) => c.phone.equals(phone))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  Future<List<Customer>> getCustomersByEmail(String email) {
    return (select(customers)
          ..where((c) => c.email.lower().equals(email.toLowerCase()))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  Future<List<Customer>> getUnsyncedCustomers() {
    return (select(customers)
          ..where((c) => c.isSynced.equals(false))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  Future<void> markAsSynced(int id) {
    return (update(customers)..where((c) => c.id.equals(id)))
        .write(CustomersCompanion(
          isSynced: const Value(true),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> updateCustomer(CustomersCompanion customer) {
    return (update(customers)..where((c) => c.id.equals(customer.id.value)))
        .write(customer.copyWith(updatedAt: Value(DateTime.now())));
  }

  Future<void> deleteCustomer(int id) {
    return (delete(customers)..where((c) => c.id.equals(id))).go();
  }
}
