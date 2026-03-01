part of '../drift_database.dart';

class Categories extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get otherName => text()();

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
