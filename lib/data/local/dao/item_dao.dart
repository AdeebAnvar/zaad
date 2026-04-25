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
  IntColumn get maximum => integer().nullable()(); // Maximum total toppings allowed for the item

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
  Items,
  ItemVariants,
  ItemToppings,
  ToppingGroups,
])
class ItemDao extends DatabaseAccessor<AppDatabase> with _$ItemDaoMixin {
  ItemDao(AppDatabase db) : super(db);

  /// ───────────── KITCHENS ─────────────

  Future<void> upsertKitchen(KitchensCompanion data) async {
    await into(kitchens).insertOnConflictUpdate(data);
  }

  Future<List<Kitchen>> getAllKitchens() => select(kitchens).get();

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
    print('''===============
    ${data.toColumns(true)}
    
     ''');
    await into(items).insertOnConflictUpdate(data);
  }

  Future<List<Item>> getAll() => select(items).get();
  Future<List<ItemVariant>> getAllVariants() => select(itemVariants).get();

  Future<Item?> getItemById(int itemId) {
    return (select(items)..where((v) => v.id.equals(itemId))).getSingleOrNull();
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

  Future<ItemVariant?> getVariantById(int variantId) {
    return (select(itemVariants)..where((v) => v.id.equals(variantId))).getSingleOrNull();
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

  Future<ItemTopping?> getToppingById(int toppingId) {
    return (select(itemToppings)..where((t) => t.id.equals(toppingId))).getSingleOrNull();
  }

  /// ───────────── TOPPING GROUPS ─────────────

  Future<List<ToppingGroup>> getToppingGroups(int itemId) {
    return (select(toppingGroups)..where((g) => g.itemId.equals(itemId))).get();
  }
}
