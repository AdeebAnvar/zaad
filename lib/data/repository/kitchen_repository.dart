import 'package:pos/data/local/drift_database.dart';

abstract class KitchenRepository {
  Future<List<Kitchen>> getAllLocalKitchens();
  Future<Kitchen?> getKitchenById(int kitchenId);
  Future<void> saveKitchen(Kitchen kitchen);
  Future<void> saveKitchens(List<Kitchen> kitchens);
}
