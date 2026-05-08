import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'dart:convert';
import 'dart:io';

class ItemRepositoryImpl implements ItemRepository {
  final AppDatabase db;
  ItemRepositoryImpl(this.db);
  static const String _debugLogPath =
      r'c:\Users\adeeb\OneDrive\Desktop\pos\pos\debug-aa2a57.log';
  static const String _debugSessionId = 'aa2a57';

  Future<int> _activeBranchId() async {
    final session = await db.sessionDao.getActiveSession();
    return session?.branchId ?? 1;
  }

  Future<Set<int>> _visibleCategoryIds(int branchId) async {
    final cats = await db.categoryDao.getVisibleForBranch(branchId);
    return cats.map((c) => c.id).toSet();
  }

  @override
  Future<List<Item>> fetchItemsFromLocal() async {
    final bid = await _activeBranchId();
    final rows = await db.itemDao.getVisibleForBranch(bid);
    // #region agent log
    await _agentLog(
      runId: 'pre-fix',
      hypothesisId: 'H5',
      location: 'item_repository_impl.dart:24',
      message: 'Fetched visible items for active session branch',
      data: {
        'active_branch_id': bid,
        'total_items': rows.length,
        'nutella_ids': rows
            .where((i) => i.name.trim().toLowerCase().contains('nutella'))
            .map((i) => i.id)
            .toList(),
      },
    );
    // #endregion
    return rows;
  }

  @override
  Stream<List<Item>> watchItemsFromLocal() async* {
    final bid = await _activeBranchId();
    yield* db.itemDao.watchVisibleForBranch(bid).asyncMap((rows) async {
      // #region agent log
      await _agentLog(
        runId: 'pre-fix',
        hypothesisId: 'H6',
        location: 'item_repository_impl.dart:47',
        message: 'Watch visible items emitted',
        data: {
          'active_branch_id': bid,
          'total_items': rows.length,
          'nutella_ids': rows
              .where((i) => i.name.trim().toLowerCase().contains('nutella'))
              .map((i) => i.id)
              .toList(),
        },
      );
      // #endregion
      return rows;
    });
  }

  @override
  Future<List<Category>> fetchCategoriesFromLocal() async {
    final bid = await _activeBranchId();
    return db.categoryDao.getVisibleForBranch(bid);
  }

  @override
  Stream<List<Category>> watchCategoriesFromLocal() async* {
    final bid = await _activeBranchId();
    yield* db.categoryDao.watchVisibleForBranch(bid);
  }

  @override
  Future<List<ItemVariant>> fetchAllVariants() async {
    final bid = await _activeBranchId();
    final visibleItemIds = (await db.itemDao.getVisibleForBranch(bid)).map((i) => i.id).toSet();
    if (visibleItemIds.isEmpty) return [];
    final all = await db.itemDao.getAllVariants();
    return all.where((v) => visibleItemIds.contains(v.itemId)).toList();
  }

  @override
  Stream<List<ItemVariant>> watchAllVariants() async* {
    final bid = await _activeBranchId();
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
    final bid = await _activeBranchId();
    final catIds = await _visibleCategoryIds(bid);
    return catIds.contains(item.categoryId) ? item : null;
  }

  Future<void> _agentLog({
    required String runId,
    required String hypothesisId,
    required String location,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    try {
      final payload = <String, dynamic>{
        'sessionId': _debugSessionId,
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await File(_debugLogPath).writeAsString(
        '${jsonEncode(payload)}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }
}
