import 'package:pos/data/local/drift_database.dart';

abstract class ItemRepository {
  Future<List<Item>> fetchItemsFromLocal();
  Stream<List<Item>> watchItemsFromLocal();
  Future<Item?> fetchItemByIdFromLocal(int id);
  Future<List<Category>> fetchCategoriesFromLocal();
  Stream<List<Category>> watchCategoriesFromLocal();
  Future<List<ItemVariant>> fetchAllVariants();
  Stream<List<ItemVariant>> watchAllVariants();
  Future<List<ItemVariant>> fetchVariantsByItem(int itemId);
  Future<ItemVariant?> fetchVariantById(int variantId);
  Future<List<ItemTopping>> fetchToppingsByItem(int itemId);
  Future<ItemTopping?> fetchToppingById(int toppingId);
  Future<List<ToppingGroup>> fetchToppingGroups(int itemId);
}
