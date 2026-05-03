part of '../drift_database.dart';

class Categories extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get otherName => text()();
  /// [CategoryCreatedUpdated.uuid] from [PullDataModel] / [CategorySyncResponse]
  TextColumn get recordUuid => text().nullable()();
  IntColumn get branchId => integer().nullable()();
  TextColumn get categorySlug => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(AppDatabase db) : super(db);

  Future<void> insertOrUpdateCategory(CategoriesCompanion data) async {
    await into(categories).insertOnConflictUpdate(data);
  }

  Future<List<Category>> getAll() => select(categories).get();
}
