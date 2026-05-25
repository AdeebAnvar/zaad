part of '../drift_database.dart';

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();

  /// Default for SQLite ALTER (legacy DBs that lacked this column). Real logins set explicitly.
  IntColumn get branchId => integer().withDefault(const Constant(1))();
  TextColumn get role => text()(); // admin / counter
  /// Current draft cart id for Take Away (persisted so cart survives navigation/reload).
  IntColumn get activeCartId => integer().nullable()();
}

@DriftAccessor(tables: [Sessions])
class SessionDao extends DatabaseAccessor<AppDatabase> with _$SessionDaoMixin {
  SessionDao(super.db);

  Future<void> saveSession(int userId, String role, int branchId) async {
    await delete(sessions).go(); // only ONE active session
    await into(sessions).insert(
      SessionsCompanion.insert(
        userId: userId,
        role: role,
        branchId: Value(branchId),
      ),
    );
  }

  Future<Session?> getActiveSession() => select(sessions).getSingleOrNull();

  /// Repairs legacy/corrupt rows where [Sessions.branchId] is missing or `<= 0`.
  Future<int?> _resolveBranchIdForSession(Session session) async {
    if (session.branchId > 0) return session.branchId;

    final user = await attachedDatabase.usersDao.findUserById(session.userId);
    if (user != null && user.branchId > 0) return user.branchId;

    final branchRows = await attachedDatabase.branchesDao.getAllBranches();
    if (branchRows.length == 1) {
      final only = branchRows.first.id;
      if (only > 0) return only;
    }
    return null;
  }

  Future<void> _persistSessionBranchId(int sessionRowId, int branchId) async {
    await (update(sessions)..where((s) => s.id.equals(sessionRowId))).write(
      SessionsCompanion(branchId: Value(branchId)),
    );
  }

  /// Active selling branch from login. Never silently defaults to `1` (avoids `INV-1-*` mislabels).
  ///
  /// When the stored session has an invalid branch, we repair from the logged-in user's
  /// [Users.branchId] (or a single local branch) before failing.
  Future<int> requireActiveBranchId() async {
    final session = await getActiveSession();
    if (session == null) {
      throw StateError('No active branch session — log in again before creating sales.');
    }

    var bid = session.branchId;
    if (bid <= 0) {
      final repaired = await _resolveBranchIdForSession(session);
      if (repaired != null && repaired > 0) {
        await _persistSessionBranchId(session.id, repaired);
        bid = repaired;
      }
    }

    if (bid <= 0) {
      throw StateError('No active branch session — log in again before creating sales.');
    }
    return bid;
  }

  Future<void> clearSession() => delete(sessions).go();

  /// Get the persisted active cart id for the current session (Drift as single source of truth).
  Future<int?> getActiveCartId() async {
    final session = await getActiveSession();
    return session?.activeCartId;
  }

  /// Persist or clear the active cart id for the current session.
  Future<void> setActiveCartId(int? cartId) async {
    final session = await getActiveSession();
    if (session == null) return;
    await (update(sessions)..where((s) => s.id.equals(session.id))).write(SessionsCompanion(activeCartId: Value(cartId)));
  }
}
