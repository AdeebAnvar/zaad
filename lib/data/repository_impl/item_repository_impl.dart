import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/item_repository.dart';

class ItemRepositoryImpl implements ItemRepository {
  final AppDatabase db;
  ItemRepositoryImpl(this.db);
  @override
  Future<List<Item>> fetchItemsFromLocal() async {
    final item = await db.itemDao.getAll();
    return item;
  }

  @override
  Future<List<Category>> fetchCategoriesFromLocal() async {
    final categories = await db.categoryDao.getAll();
    return categories;
  }

  @override
  Future<List<ItemVariant>> fetchAllVariants() async {
    return await db.itemDao.getAllVariants();
  }

  @override
  Future<List<ItemVariant>> fetchVariantsByItem(int itemId) async {
    return await db.itemDao.getVariantsByItem(itemId);
  }

  @override
  Future<ItemVariant?> fetchVariantById(int variantId) async {
    return await db.itemDao.getVariantById(variantId);
  }

  @override
  Future<List<ItemTopping>> fetchToppingsByItem(int itemId) async {
    return await db.itemDao.getToppingsByItem(itemId);
  }

  @override
  Future<ItemTopping?> fetchToppingById(int toppingId) async {
    return await db.itemDao.getToppingById(toppingId);
  }

  @override
  Future<List<ToppingGroup>> fetchToppingGroups(int itemId) async {
    return await db.itemDao.getToppingGroups(itemId);
  }

  @override
  Future<Item?> fetchItemByIdFromLocal(int id) async {
    return await db.itemDao.getItemById(id);
  }
}
