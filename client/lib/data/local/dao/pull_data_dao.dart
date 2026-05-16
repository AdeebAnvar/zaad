part of '../drift_database.dart';

// --- Mirrors [CategorySyncResponse] / [CategoryCreatedUpdated] (per [PullDataModel] key) ---

class PullCategoryRows extends Table {
  /// JSON key, e.g. `category`, `variations`, `driver`, `chairs`.
  TextColumn get resourceKey => text()();
  IntColumn get id => integer()();
  TextColumn get uuid => text()();
  IntColumn get branchId => integer()();
  TextColumn get categoryName => text()();
  TextColumn get categorySlug => text()();
  TextColumn get otherName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {resourceKey, id};
}

// --- Mirrors [FloorsModel] / [FloorsCreatedUpdated] for `unit`, `paymentMethods`, `floors` ---

class PullFloorRows extends Table {
  TextColumn get resourceKey => text()();
  IntColumn get id => integer()();
  TextColumn get uuid => text()();
  IntColumn get branchId => integer()();
  TextColumn get floorName => text().nullable()();
  TextColumn get floorSlug => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get paymentMethodName => text().nullable()();
  TextColumn get paymentMethodSlug => text().nullable()();
  TextColumn get unitName => text().nullable()();
  TextColumn get unitSlug => text().nullable()();

  @override
  Set<Column> get primaryKey => {resourceKey, id};
}

// --- [DeliveryServiceModel] / [DeliveryServiceCreatedUpdated] ---

class PullDeliveryServiceRows extends Table {
  IntColumn get id => integer()();
  TextColumn get uuid => text()();
  IntColumn get branchId => integer()();
  TextColumn get serviceName => text()();
  TextColumn get serviceNameSlug => text()();
  TextColumn get driverStatus => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- [ItemSyncResponse] / [ItemCreatedUpdated] (lists stored as JSON) ---

class PullItemRows extends Table {
  IntColumn get id => integer()();
  TextColumn get uuid => text()();
  IntColumn get branchId => integer()();
  IntColumn get categoryId => integer()();
  IntColumn get unitId => integer()();
  TextColumn get itemName => text()();
  TextColumn get itemSlug => text()();
  TextColumn get itemOtherName => text().nullable()();
  TextColumn get kitchenIds => text()();
  TextColumn get toppingIds => text().nullable()();
  TextColumn get tax => text()();
  TextColumn get taxPercent => text().nullable()();
  IntColumn get minimumQty => integer()();
  TextColumn get itemType => text()();
  TextColumn get stockApplicable => text()();
  TextColumn get ingredient => text()();
  TextColumn get orderType => text()();
  TextColumn get deliveryService => text()();
  TextColumn get image => text()();
  TextColumn get expiryDate => text().nullable()();
  TextColumn get active => text()();
  IntColumn get isVariant => integer()();
  /// JSON: item_variations array from API
  TextColumn get itemVariationsJson => text().nullable()();
  /// JSON: itemprice array from API
  TextColumn get itempriceJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Last [Pagination] seen per resource (for resumable pull) ---

class SyncPaginationStates extends Table {
  /// Stable key, e.g. `pull_category`, `pull_item`, `category`, etc.
  TextColumn get resourceKey => text()();
  IntColumn get currentPage => integer().nullable()();
  IntColumn get pageFrom => integer().nullable()();
  IntColumn get lastPage => integer().nullable()();
  IntColumn get perPage => integer().nullable()();
  IntColumn get pageTo => integer().nullable()();
  IntColumn get total => integer().nullable()();

  @override
  Set<Column> get primaryKey => {resourceKey};
}

@DriftAccessor(
  tables: [
    PullCategoryRows,
    PullFloorRows,
    PullDeliveryServiceRows,
    PullItemRows,
    SyncPaginationStates,
  ],
)
class PullDataDao extends DatabaseAccessor<AppDatabase> with _$PullDataDaoMixin {
  PullDataDao(AppDatabase db) : super(db);
  static const String _syncMetaTable = 'sync_meta_state';
  static const String _pullLastSyncedAtKey = 'pull_last_synced_at';

  Future<void> upsertPullCategory(PullCategoryRowsCompanion row) async {
    await into(pullCategoryRows).insertOnConflictUpdate(row);
  }

  Future<void> upsertPullFloor(PullFloorRowsCompanion row) async {
    await into(pullFloorRows).insertOnConflictUpdate(row);
  }

  Future<void> upsertPullDeliveryService(PullDeliveryServiceRowsCompanion row) async {
    await into(pullDeliveryServiceRows).insertOnConflictUpdate(row);
  }

  Future<void> upsertPullItem(PullItemRowsCompanion row) async {
    await into(pullItemRows).insertOnConflictUpdate(row);
  }

  /// Category rows synced from tenant `category` payload (LAN publisher uses this snapshot).
  Future<List<PullCategoryRow>> lanPublishMirrorCategories() async {
    return (select(pullCategoryRows)
          ..where((t) => t.resourceKey.equals('category')))
        .get();
  }

  Future<void> savePagination(SyncPaginationStatesCompanion state) async {
    await into(syncPaginationStates).insertOnConflictUpdate(state);
  }

  Future<List<PullCategoryRow>> getOffersForBranch(int branchId) {
    return () async {
      final scoped = await ((select(pullCategoryRows)
            ..where((t) => t.resourceKey.equals('offers'))
            ..where((t) => t.branchId.equals(branchId))
            ..where((t) => t.deletedAt.isNull()))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();
      if (scoped.isNotEmpty) return scoped;

      // Fallback for legacy/partial data where offer branch_id may not match active session.
      return ((select(pullCategoryRows)
            ..where((t) => t.resourceKey.equals('offers'))
            ..where((t) => t.deletedAt.isNull()))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();
    }();
  }

  /// Rows from `pull_records.expenseCategory` (cloud sync payload).
  Future<List<PullCategoryRow>> getExpenseCategoriesForBranch(int branchId) async {
    final scoped = await ((select(pullCategoryRows)
          ..where((t) => t.resourceKey.equals('expenseCategory'))
          ..where((t) => t.branchId.equals(branchId))
          ..where((t) => t.deletedAt.isNull()))
        ..orderBy([(t) => OrderingTerm.asc(t.categoryName)]))
        .get();
    if (scoped.isNotEmpty) return scoped;

    return ((select(pullCategoryRows)
          ..where((t) => t.resourceKey.equals('expenseCategory'))
          ..where((t) => t.deletedAt.isNull()))
        ..orderBy([(t) => OrderingTerm.asc(t.categoryName)]))
        .get();
  }

  /// Rows from `pull_records.paymentMethods` (cloud sync payload).
  Future<List<PullFloorRow>> getPaymentMethodsForBranch(int branchId) async {
    final scoped = await ((select(pullFloorRows)
          ..where((t) => t.resourceKey.equals('paymentMethods'))
          ..where((t) => t.branchId.equals(branchId))
          ..where((t) => t.deletedAt.isNull()))
        ..orderBy([(t) => OrderingTerm.asc(t.paymentMethodName)]))
        .get();
    if (scoped.isNotEmpty) return scoped;

    return ((select(pullFloorRows)
          ..where((t) => t.resourceKey.equals('paymentMethods'))
          ..where((t) => t.deletedAt.isNull()))
        ..orderBy([(t) => OrderingTerm.asc(t.paymentMethodName)]))
        .get();
  }

  /// Last saved pagination row for a resource (for resume / UI).
  Future<SyncPaginationState?> getPaginationState(String resourceKey) {
    return (select(syncPaginationStates)..where((s) => s.resourceKey.equals(resourceKey)))
        .getSingleOrNull();
  }

  Future<void> _ensureSyncMetaTable() async {
    await customStatement(
      'CREATE TABLE IF NOT EXISTS $_syncMetaTable (meta_key TEXT PRIMARY KEY, meta_value TEXT)',
    );
  }

  Future<String?> getPullLastSyncedAt() async {
    await _ensureSyncMetaTable();
    final rows = await customSelect(
      'SELECT meta_value FROM $_syncMetaTable WHERE meta_key = ? LIMIT 1',
      variables: <Variable<Object>>[
        const Variable<String>(_pullLastSyncedAtKey),
      ],
      readsFrom: {},
    ).get();
    if (rows.isEmpty) return null;
    final value = rows.first.read<String>('meta_value').trim();
    return value.isEmpty ? null : value;
  }

  Future<void> savePullLastSyncedAt(String lastSyncedAt) async {
    final normalized = lastSyncedAt.trim();
    if (normalized.isEmpty) return;
    await _ensureSyncMetaTable();
    await customStatement(
      'INSERT INTO $_syncMetaTable(meta_key, meta_value) VALUES(?, ?) '
      'ON CONFLICT(meta_key) DO UPDATE SET meta_value = excluded.meta_value',
      <Object>[_pullLastSyncedAtKey, normalized],
    );
  }
}
