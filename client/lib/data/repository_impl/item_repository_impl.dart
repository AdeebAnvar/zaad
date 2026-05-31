import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/item_repository.dart';

class ItemRepositoryImpl implements ItemRepository {
  final AppDatabase db;
  ItemRepositoryImpl(this.db);

  Future<int?> _activeBranchIdOrNull() async {
    final bid = (await db.sessionDao.getActiveSession())?.branchId;
    if (bid == null || bid <= 0) return null;
    return bid;
  }

  Future<Set<int>> _visibleCategoryIds(int branchId) async {
    final cats = await db.categoryDao.getVisibleForBranch(branchId);
    return cats.map((c) => c.id).toSet();
  }

  @override
  Future<List<Item>> fetchItemsFromLocal() async {
    final bid = await _activeBranchIdOrNull();
    if (bid == null) return [];
    return db.itemDao.getVisibleForBranch(bid);
  }

  @override
  Stream<List<Item>> watchItemsFromLocal() async* {
    final bid = await _activeBranchIdOrNull();
    if (bid == null) {
      yield <Item>[];
      return;
    }
    yield* db.itemDao.watchVisibleForBranch(bid);
  }

  @override
  Future<List<Category>> fetchCategoriesFromLocal() async {
    final bid = await _activeBranchIdOrNull();
    if (bid == null) return [];
    return db.categoryDao.getVisibleForBranch(bid);
  }

  @override
  Stream<List<Category>> watchCategoriesFromLocal() async* {
    final bid = await _activeBranchIdOrNull();
    if (bid == null) {
      yield <Category>[];
      return;
    }
    yield* db.categoryDao.watchVisibleForBranch(bid);
  }

  @override
  Future<List<ItemVariant>> fetchAllVariants() async {
    final bid = await _activeBranchIdOrNull();
    if (bid == null) return [];
    final visibleItemIds = (await db.itemDao.getVisibleForBranch(bid)).map((i) => i.id).toSet();
    if (visibleItemIds.isEmpty) return [];
    final all = await db.itemDao.getAllVariants();
    return all.where((v) => visibleItemIds.contains(v.itemId)).toList();
  }

  @override
  Stream<List<ItemVariant>> watchAllVariants() async* {
    final bid = await _activeBranchIdOrNull();
    if (bid == null) {
      yield const <ItemVariant>[];
      return;
    }
    await for (final all in db.itemDao.watchAllVariants()) {
      final visibleItemIds = (await db.itemDao.getVisibleForBranch(bid)).map((i) => i.id).toSet();
      if (visibleItemIds.isEmpty) {
        yield const <ItemVariant>[];
      } else {
        yield all.where((v) => visibleItemIds.contains(v.itemId)).toList();
      }
    }
  }

  @override
  Future<Set<int>> fetchToppingItemIds() async {
    final bid = await _activeBranchIdOrNull();
    if (bid == null) return {};
    final visibleItemIds = (await db.itemDao.getVisibleForBranch(bid)).map((i) => i.id).toSet();
    if (visibleItemIds.isEmpty) return {};
    final all = await db.itemDao.getAllToppings();
    return all.map((t) => t.itemId).where(visibleItemIds.contains).toSet();
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
    final item = await db.itemDao.getItemById(id);
    if (item == null) return null;
    final bid = await _activeBranchIdOrNull();
    if (bid == null) return null;
    final catIds = await _visibleCategoryIds(bid);
    return catIds.contains(item.categoryId) ? item : null;
  }
}
