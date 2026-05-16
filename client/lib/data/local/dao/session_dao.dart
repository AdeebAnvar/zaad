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
  SessionDao(AppDatabase db) : super(db);

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

  /// Active selling branch from login. Never silently defaults to `1` (avoids `INV-1-*` mislabels).
  Future<int> requireActiveBranchId() async {
    final bid = (await getActiveSession())?.branchId;
    if (bid == null || bid <= 0) {
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
