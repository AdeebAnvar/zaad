import 'package:drift/drift.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/kitchen_repository.dart';

class KitchenRepositoryImpl implements KitchenRepository {
  final AppDatabase db;

  KitchenRepositoryImpl(this.db);

  @override
  Future<List<Kitchen>> getAllLocalKitchens() {
    return db.itemDao.getAllKitchens();
  }

  @override
  Future<Kitchen?> getKitchenById(int kitchenId) {
    return db.itemDao.getKitchenById(kitchenId);
  }

  @override
  Future<void> saveKitchen(Kitchen kitchen) async {
    await db.itemDao.upsertKitchen(
      KitchensCompanion(
        id: Value(kitchen.id),
        name: Value(kitchen.name),
        printerIp: Value(kitchen.printerIp),
        printerPort: Value(kitchen.printerPort),
      ),
    );
  }

  @override
  Future<void> saveKitchens(List<Kitchen> kitchens) async {
    for (final kitchen in kitchens) {
      await saveKitchen(kitchen);
    }
  }
}
