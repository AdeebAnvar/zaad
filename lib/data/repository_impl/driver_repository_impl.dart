import 'package:drift/drift.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/driver_repository.dart';

class DriverRepositoryImpl implements DriverRepository {
  final AppDatabase db;

  DriverRepositoryImpl(this.db);

  static const _defaultDrivers = <MapEntry<int, String>>[
    MapEntry(1, 'Driver A'),
    MapEntry(2, 'Driver B'),
    MapEntry(3, 'Driver C'),
  ];

  @override
  Future<List<Driver>> getAll() async {
    final list = await db.driversDao.getAll();
    if (list.isEmpty) {
      for (final e in _defaultDrivers) {
        await db.driversDao.upsertDriver(
          DriversCompanion.insert(id: Value(e.key), name: e.value),
        );
      }
      return db.driversDao.getAll();
    }
    return list;
  }
}
