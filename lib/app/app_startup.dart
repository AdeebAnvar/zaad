import '../data/local/drift_database.dart';
import '../core/constants/enums.dart';

class AppStartup {
  final AppDatabase db;

  AppStartup(this.db);

  Future<UserType?> checkLoggedInUser() async {
    final session = await db.sessionDao.getActiveSession();

    if (session == null) return null;

    return session.role == "admin" ? UserType.admin : UserType.counter;
  }
}
