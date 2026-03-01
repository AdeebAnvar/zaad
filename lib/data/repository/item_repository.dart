import 'package:pos/data/local/drift_database.dart';

abstract class ItemRepository {
  Future<List<Item>> fetchItemsFromLocal();
  Future<Item?> fetchItemByIdFromLocal(int id);
  Future<List<Category>> fetchCategoriesFromLocal();
  Future<List<ItemVariant>> fetchVariantsByItem(int itemId);
  Future<ItemVariant?> fetchVariantById(int variantId);
  Future<List<ItemTopping>> fetchToppingsByItem(int itemId);
  Future<ItemTopping?> fetchToppingById(int toppingId);
  Future<List<ToppingGroup>> fetchToppingGroups(int itemId);
}
