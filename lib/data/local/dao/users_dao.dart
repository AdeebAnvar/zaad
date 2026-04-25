part of '../drift_database.dart';

class Users extends Table {
  IntColumn get id => integer()(); // server ID

  IntColumn get branchId => integer()();

  TextColumn get name => text()();

  TextColumn get usertype => text()();

  TextColumn get mobilePassword => text()();

  TextColumn get permissions => text()(); // JSON encoded

  TextColumn get role => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// =========================
/// DAO
/// =========================
@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(AppDatabase db) : super(db);

  /// =========================
  /// INSERT / UPSERT USERS
  /// =========================
  Future<void> insertUsers(List<UserModel> usersList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        users,
        usersList.map((u) => _toCompanion(u)).toList(),
      );
    });
  }

  /// =========================
  /// SINGLE INSERT (optional)
  /// =========================
  Future<void> insertUser(UserModel user) async {
    await into(users).insertOnConflictUpdate(_toCompanion(user));
  }

  /// =========================
  /// GET ALL USERS
  /// =========================
  Future<List<UserModel>> getAllUsers() async {
    final data = await select(users).get();
    return data.map(_toModel).toList();
  }

  /// =========================
  /// LOGIN (LOCAL AUTH)
  /// =========================
  Future<UserModel?> findUser(
    String username,
    String md5Password,
  ) async {
    final result = await (select(users)..where((u) => u.name.equals(username) & u.mobilePassword.equals(md5Password))).getSingleOrNull();

    if (result == null) return null;

    return _toModel(result);
  }

  /// =========================
  /// FIND BY ID
  /// =========================
  Future<UserModel?> findUserById(int id) async {
    final result = await (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

    if (result == null) return null;

    return _toModel(result);
  }

  /// =========================
  /// DELETE USERS (SYNC)
  /// =========================
  Future<void> deleteUsers(List<int> ids) async {
    await (delete(users)..where((u) => u.id.isIn(ids))).go();
  }

  /// =========================
  /// CLEAR TABLE (optional)
  /// =========================
  Future<void> clearUsers() async {
    await delete(users).go();
  }

  /// =========================
  /// MAPPERS
  /// =========================

  /// Model → DB
  UsersCompanion _toCompanion(UserModel user) {
    return UsersCompanion(
      id: Value(user.id),
      branchId: Value(user.branchId),
      name: Value(user.name),
      usertype: Value(user.usertype),
      mobilePassword: Value(user.mobilePassword),
      permissions: Value(jsonEncode(user.permissions)),
      role: Value(user.type.name),
    );
  }

  /// DB → Model
  UserModel _toModel(User user) {
    return UserModel(
      id: user.id,
      branchId: user.branchId,
      name: user.name,
      usertype: user.usertype,
      mobilePassword: user.mobilePassword,
      permissions: List<String>.from(jsonDecode(user.permissions)),
      type: UserType.values.firstWhere(
        (e) => e.name == user.role,
        orElse: () => UserType.counter,
      ),
    );
  }
}
