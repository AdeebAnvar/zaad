part of '../drift_database.dart';

class Kitchens extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get printerIp => text().nullable()();
  IntColumn get printerPort => integer().withDefault(const Constant(9100))();

  /// [KitchensCreatedUpdated] from [KitchenSyncResponse]
  TextColumn get recordUuid => text().nullable()();
  IntColumn get branchId => integer().nullable()();
  TextColumn get printerDetails => text().nullable()();
  TextColumn get printerType => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Local config: printer IP/port per kitchen. kitchen_id=0 means default bill printer.
class KitchenPrinters extends Table {
  IntColumn get kitchenId => integer()();
  TextColumn get printerIp => text()();
  IntColumn get printerPort => integer().withDefault(const Constant(9100))();
  @override
  Set<Column> get primaryKey => {kitchenId};
}

class Items extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get otherName => text()();
  TextColumn get sku => text()();
  RealColumn get price => real()();
  IntColumn get stock => integer()();

  /// When false, stock quantity is ignored in UI and sales logic.
  BoolColumn get stockEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get imagePath => text().nullable()();
  TextColumn get localImagePath => text().nullable()();
  TextColumn get categoryName => text()();
  TextColumn get categoryOtherName => text()();
  TextColumn get barcode => text()();
  IntColumn get categoryId => integer()();
  IntColumn get kitchenId => integer().nullable()();
  TextColumn get kitchenName => text().nullable()();

  /// Delivery partner id/name - items filtered by partner when in delivery mode
  TextColumn get deliveryPartner => text().nullable()();

  /// Canonical `take_away.dine_in` style keys from tenant `order_type` (see [parseItemOrderChannelsFromApi]).
  /// Null/empty = available on all sale modes (legacy).
  TextColumn get allowedOrderChannels => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class ItemVariants extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer()();
  TextColumn get name => text()();
  RealColumn get price => real()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {itemId, name},
      ];
}

class ItemToppings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  IntColumn get maxQty => integer().withDefault(const Constant(1))();
  IntColumn get maximum => integer().nullable()(); // Synthetic group id: itemId*100000 + categoryId
  /// From API `toppings.toppings_category_id` (when [maximum] is missing, dialog still groups by category).
  IntColumn get toppingsCategoryId => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {itemId, name},
      ];
}

class ToppingGroups extends Table {
  IntColumn get id => integer()();
  IntColumn get itemId => integer()();
  TextColumn get name => text()(); // ICECREAM / GENERAL
  IntColumn get min => integer().withDefault(const Constant(0))();
  IntColumn get max => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [
  Kitchens,
  KitchenPrinters,
  Categories,
  Items,
  ItemVariants,
  ItemToppings,
  ToppingGroups,
])
class ItemDao extends DatabaseAccessor<AppDatabase> with _$ItemDaoMixin {
  ItemDao(super.db);

  /// ───────────── KITCHENS ─────────────

  Future<void> upsertKitchen(KitchensCompanion data) async {
    await into(kitchens).insertOnConflictUpdate(data);
  }

  Future<List<Kitchen>> getAllKitchens() => select(kitchens).get();

  Future<List<Kitchen>> getKitchensForBranch(int branchId) {
    return (select(kitchens)..where((k) => k.branchId.equals(branchId) | k.branchId.isNull())).get();
  }

  Future<Kitchen?> getKitchenById(int kitchenId) {
    return (select(kitchens)..where((k) => k.id.equals(kitchenId))).getSingleOrNull();
  }

  /// Update printer IP/port for a kitchen (connects device to printer).
  Future<void> updateKitchenPrinter({
    required int kitchenId,
    required String printerIp,
    int printerPort = 9100,
  }) async {
    await (update(kitchens)..where((k) => k.id.equals(kitchenId))).write(
      KitchensCompanion(
        printerIp: Value(printerIp),
        printerPort: Value(printerPort),
      ),
    );
  }

  /// ───────────── KITCHEN PRINTERS (local config) ─────────────

  Future<void> upsertKitchenPrinter(KitchenPrintersCompanion data) async {
    await into(kitchenPrinters).insertOnConflictUpdate(data);
  }

  Future<KitchenPrinter?> getPrinterByKitchenId(int kitchenId) {
    return (select(kitchenPrinters)..where((k) => k.kitchenId.equals(kitchenId))).getSingleOrNull();
  }

  Future<List<KitchenPrinter>> getAllKitchenPrinters() => select(kitchenPrinters).get();

  /// kitchen_id=0 is the default bill printer
  Future<KitchenPrinter?> getBillPrinter() => getPrinterByKitchenId(0);

  /// ───────────── ITEMS ─────────────

  /// Insert OR update stock if SKU exists
  Future<void> upsertItem(ItemsCompanion data) async {
    await into(items).insertOnConflictUpdate(data);
  }

  Future<List<Item>> getAll() => select(items).get();

  /// Items whose category belongs to [branchId] or has no branch (shared catalog).
  Future<List<Item>> getVisibleForBranch(int branchId) async {
    final catRows = await (select(categories)..where((c) => c.branchId.equals(branchId) | c.branchId.isNull())).get();
    if (catRows.isEmpty) return [];
    final ids = catRows.map((c) => c.id).toList();
    return (select(items)..where((i) => i.categoryId.isIn(ids))).get();
  }

  Stream<List<Item>> watchVisibleForBranch(int branchId) {
    final q = select(items).join([
      innerJoin(categories, categories.id.equalsExp(items.categoryId)),
    ])
      ..where(categories.branchId.equals(branchId) | categories.branchId.isNull())
      ..orderBy([OrderingTerm.asc(items.name)]);
    return q.watch().map((rows) => rows.map((r) => r.readTable(items)).toList());
  }

  Future<List<ItemVariant>> getAllVariants() => select(itemVariants).get();

  Stream<List<ItemVariant>> watchAllVariants() => select(itemVariants).watch();

  Future<Item?> getItemById(int itemId) {
    return (select(items)..where((v) => v.id.equals(itemId))).getSingleOrNull();
  }

  Future<List<Item>> getItemsByIds(List<int> itemIds) async {
    if (itemIds.isEmpty) return const [];
    return (select(items)..where((i) => i.id.isIn(itemIds))).get();
  }

  /// Catalog rows restricted to ids in [itemIds] and categories visible at [branchId]
  /// (same rule as POS item visibility — used for thermal print routing without N+1 lookups).
  Future<List<Item>> getVisibleItemsForIds({
    required int branchId,
    required List<int> itemIds,
  }) async {
    if (itemIds.isEmpty) return const [];
    final catRows =
        await (select(categories)..where((c) => c.branchId.equals(branchId) | c.branchId.isNull())).get();
    if (catRows.isEmpty) return const [];
    final catIds = catRows.map((c) => c.id).toList();
    return (select(items)..where((i) => i.id.isIn(itemIds) & i.categoryId.isIn(catIds))).get();
  }

  /// ───────────── VARIANTS ─────────────

  Future<void> upsertVariant(ItemVariantsCompanion data) async {
    // Check if variant with same itemId and name exists (unique constraint)
    final itemId = data.itemId.value;
    final name = data.name.value;

    final existing = await (select(itemVariants)..where((v) => v.itemId.equals(itemId) & v.name.equals(name))).getSingleOrNull();

    if (existing != null) {
      // Update existing variant
      await (update(itemVariants)..where((v) => v.id.equals(existing.id))).write(
        ItemVariantsCompanion(
          itemId: data.itemId,
          name: data.name,
          price: data.price,
        ),
      );
    } else {
      // Insert new variant
      await into(itemVariants).insert(data);
    }
  }

  Future<List<ItemVariant>> getVariantsByItem(int itemId) {
    return (select(itemVariants)..where((v) => v.itemId.equals(itemId))).get();
  }

  Future<void> deleteVariantsByItem(int itemId) async {
    await (delete(itemVariants)..where((v) => v.itemId.equals(itemId))).go();
  }

  /// Removes variants not in [keepNames] unless an open-cart line still references them.
  Future<void> pruneVariantsByItemKeepingNames(int itemId, Set<String> keepNames) async {
    final existing = await getVariantsByItem(itemId);
    for (final v in existing) {
      if (keepNames.contains(v.name)) continue;
      final inUse = await attachedDatabase.customSelect(
        'SELECT 1 FROM cart_items WHERE item_variant_id = ? LIMIT 1',
        variables: [Variable.withInt(v.id)],
        readsFrom: {itemVariants, attachedDatabase.cartItems},
      ).getSingleOrNull();
      if (inUse != null) continue;
      await (delete(itemVariants)..where((x) => x.id.equals(v.id))).go();
    }
  }

  /// Clears cart variant picks for [itemId] so catalog variant rows can be replaced.
  Future<void> detachCartVariantRefsForItem(int itemId) async {
    await attachedDatabase.customStatement(
      'UPDATE cart_items SET item_variant_id = NULL '
      'WHERE item_variant_id IN (SELECT id FROM item_variants WHERE item_id = ?)',
      [itemId],
    );
  }

  /// Clears cart topping picks for [itemId] so catalog topping rows can be replaced.
  Future<void> detachCartToppingRefsForItem(int itemId) async {
    await attachedDatabase.customStatement(
      'UPDATE cart_items SET item_topping_id = NULL '
      'WHERE item_topping_id IN (SELECT id FROM item_toppings WHERE item_id = ?)',
      [itemId],
    );
  }

  /// Item ids still referenced by [cart_items] (open carts / in-progress sales).
  Future<Set<int>> itemIdsReferencedByCart(Iterable<int> itemIds) async {
    final ids = itemIds.toList();
    if (ids.isEmpty) return {};
    final rows = await (attachedDatabase.selectOnly(attachedDatabase.cartItems)
          ..addColumns([attachedDatabase.cartItems.itemId])
          ..where(attachedDatabase.cartItems.itemId.isIn(ids)))
        .get();
    return rows.map((r) => r.read(attachedDatabase.cartItems.itemId)!).toSet();
  }

  Future<ItemVariant?> getVariantById(int variantId) {
    return (select(itemVariants)..where((v) => v.id.equals(variantId))).getSingleOrNull();
  }

  Future<List<ItemVariant>> getVariantsByIds(List<int> variantIds) async {
    if (variantIds.isEmpty) return const [];
    return (select(itemVariants)..where((v) => v.id.isIn(variantIds))).get();
  }

  Future<List<ItemVariant>> getVariants() {
    return (select(itemVariants)).get();
  }

  /// ───────────── TOPPINGS ─────────────

  Future<void> upsertTopping(ItemToppingsCompanion data) async {
    // Check if topping with same itemId and name exists (unique constraint)
    final itemId = data.itemId.value;
    final name = data.name.value;

    final existing = await (select(itemToppings)..where((t) => t.itemId.equals(itemId) & t.name.equals(name))).getSingleOrNull();

    if (existing != null) {
      // Update existing topping
      await (update(itemToppings)..where((t) => t.id.equals(existing.id))).write(
        ItemToppingsCompanion(
          itemId: data.itemId,
          name: data.name,
          price: data.price,
          maxQty: data.maxQty,
          maximum: data.maximum,
          toppingsCategoryId: data.toppingsCategoryId,
        ),
      );
    } else {
      // Insert new topping
      await into(itemToppings).insert(data);
    }
  }

  Future<List<ItemTopping>> getToppingsByItem(int itemId) {
    return (select(itemToppings)..where((t) => t.itemId.equals(itemId))).get();
  }

  Future<List<ItemTopping>> getAllToppings() => select(itemToppings).get();

  Future<void> deleteToppingsByItem(int itemId) async {
    await (delete(itemToppings)..where((t) => t.itemId.equals(itemId))).go();
  }

  Future<ItemTopping?> getToppingById(int toppingId) {
    return (select(itemToppings)..where((t) => t.id.equals(toppingId))).getSingleOrNull();
  }

  Future<List<ItemTopping>> getToppingsByIds(List<int> toppingIds) async {
    if (toppingIds.isEmpty) return const [];
    return (select(itemToppings)..where((t) => t.id.isIn(toppingIds))).get();
  }

  /// ───────────── TOPPING GROUPS ─────────────

  Future<List<ToppingGroup>> getToppingGroups(int itemId) {
    return (select(toppingGroups)..where((g) => g.itemId.equals(itemId))).get();
  }

  Future<void> upsertToppingGroup(ToppingGroupsCompanion data) async {
    await into(toppingGroups).insertOnConflictUpdate(data);
  }

  Future<void> deleteToppingGroupsByItem(int itemId) async {
    await (delete(toppingGroups)..where((g) => g.itemId.equals(itemId))).go();
  }
}
