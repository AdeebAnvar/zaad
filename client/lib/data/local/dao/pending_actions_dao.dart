part of '../drift_database.dart';

/// Outbound LAN hub mutations while offline (LOCAL mode only).
class PendingActions extends Table {
  TextColumn get id => text()();

  /// CREATE_ORDER | UPDATE_ORDER | DELETE_ORDER
  TextColumn get type => text()();

  /// JSON payload (shape depends on [type]).
  TextColumn get payload => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// PENDING | SYNCED | FAILED
  TextColumn get status => text().withDefault(const Constant('PENDING'))();

  DateTimeColumn get nextRetryAfter => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [PendingActions])
class PendingActionsDao extends DatabaseAccessor<AppDatabase>
    with _$PendingActionsDaoMixin {
  PendingActionsDao(super.db);

  Future<void> insertRow(PendingActionsCompanion row) =>
      into(pendingActions).insert(row);

  Future<List<PendingAction>> pendingReady(DateTime now) {
    return (select(pendingActions)
          ..where((t) => t.status.equals('PENDING'))
          ..where(
            (t) =>
                t.nextRetryAfter.isNull() |
                t.nextRetryAfter.isSmallerOrEqualValue(now),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> updateRow(String id, PendingActionsCompanion patch) =>
      (update(pendingActions)..where((t) => t.id.equals(id))).write(patch);

  Future<void> deleteById(String id) =>
      (delete(pendingActions)..where((t) => t.id.equals(id))).go();

  Future<int> countPending() async {
    final rows = await (select(pendingActions)
          ..where((t) => t.status.equals('PENDING')))
        .get();
    return rows.length;
  }

  Future<int> countFailed() async {
    final rows = await (select(pendingActions)
          ..where((t) => t.status.equals('FAILED')))
        .get();
    return rows.length;
  }

  /// After LAN/internet returns, give permanently failed hub POSTs another chance.
  Future<void> resetFailedToPending() async {
    await (update(pendingActions)..where((t) => t.status.equals('FAILED'))).write(
      const PendingActionsCompanion(
        status: Value('PENDING'),
        retryCount: Value(0),
        nextRetryAfter: Value(null),
      ),
    );
  }

  /// Pending CREATE for this local order id (at most one expected).
  Future<PendingAction?> findPendingCreateForLocalOrder(int localOrderId) async {
    final rows = await (select(pendingActions)
          ..where((t) => t.status.equals('PENDING'))
          ..where((t) => t.type.equals('CREATE_ORDER')))
        .get();
    for (final r in rows) {
      try {
        final d = jsonDecode(r.payload);
        if (d is Map && d['local_order_id'] == localOrderId) {
          return r;
        }
      } catch (_) {}
    }
    return null;
  }
}
