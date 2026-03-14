part of '../drift_database.dart';

class DeliveryPartners extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [DeliveryPartners])
class DeliveryPartnersDao extends DatabaseAccessor<AppDatabase> with _$DeliveryPartnersDaoMixin {
  DeliveryPartnersDao(AppDatabase db) : super(db);

  Future<void> upsertDeliveryPartner(Insertable<DeliveryPartner> data) async {
    await into(deliveryPartners).insertOnConflictUpdate(data);
  }

  Future<List<DeliveryPartner>> getAll() => select(deliveryPartners).get();

  Future<DeliveryPartner?> getById(int id) {
    return (select(deliveryPartners)..where((d) => d.id.equals(id))).getSingleOrNull();
  }
}
