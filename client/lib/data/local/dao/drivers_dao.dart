part of '../drift_database.dart';

class Drivers extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [Drivers])
class DriversDao extends DatabaseAccessor<AppDatabase> with _$DriversDaoMixin {
  DriversDao(AppDatabase db) : super(db);

  Future<void> upsertDriver(Insertable<Driver> data) async {
    await into(drivers).insertOnConflictUpdate(data);
  }

  Future<List<Driver>> getAll() => select(drivers).get();
}
