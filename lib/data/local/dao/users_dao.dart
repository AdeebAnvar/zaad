part of '../drift_database.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text()();
  TextColumn get password => text()();
  TextColumn get employeeId => text()();
  IntColumn get companyId => integer()();
  TextColumn get companyName => text()();
  TextColumn get branchName => text()();
  TextColumn get companyLogo => text()();
  TextColumn get companyLogoLocal => text()();
  IntColumn get branchId => integer()();
  TextColumn get role => text()();
}

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(AppDatabase db) : super(db);

  Future<List<User>> getAllUsers() => select(users).get();

  Future<void> insertUser(UsersCompanion user) => into(users).insert(user);

  Future<User?> findUser(String username, String password) {
    print('jbegjk ${users.id}');
    print('jbegjk ${select(users)}');
    return (select(users)
          ..where(
            (u) => u.username.equals(username) & u.password.equals(password),
          ))
        .getSingleOrNull();
  }

  Future<User?> findUserById(int id) {
    select(users).get().then((va) {
      print('sgfsf3 ${id}');
      for (var v in va) {
        print('sgfsf ${v.id}');
        print('sgfsf ${v.username}');
      }
    });
    return (select(users)
          ..where(
            (u) => u.id.equals(id),
          ))
        .getSingleOrNull();
  }
}
