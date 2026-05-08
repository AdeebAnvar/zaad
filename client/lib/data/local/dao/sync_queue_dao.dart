part of '../drift_database.dart';

/// Outbound LAN events to MAIN (`PENDING` → `SENT` → `ACKED`, or `FAILED`).
class SyncOutbox extends Table {
  /// Same as outbound [PosSyncEnvelope.eventId].
  TextColumn get id => text()();

  TextColumn get eventType => text()();

  TextColumn get payload => text()();

  /// PENDING | SENT | ACKED | FAILED
  TextColumn get status => text().withDefault(const Constant('PENDING'))();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get nextRetryAfter => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Persist every inbound event before projecting into domain tables.
class SyncInbox extends Table {
  TextColumn get id => text()();

  TextColumn get eventId => text().unique()();

  TextColumn get type => text()();

  TextColumn get payload => text()();

  TextColumn get rawEnvelope => text()();

  DateTimeColumn get receivedAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get applied => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [SyncOutbox, SyncInbox])
class SyncQueueDao extends DatabaseAccessor<AppDatabase> with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<void> insertOutbox(SyncOutboxCompanion row) => into(syncOutbox).insert(row);

  /// Not `ACKED`, respecting FAILED backoff windows.
  Future<List<SyncOutboxData>> outboxWorkQueue(DateTime now) {
    return (select(syncOutbox)
          ..where((t) => t.status.isNotValue('ACKED'))
          ..where(
            (t) =>
                t.status.equals('PENDING') |
                t.status.equals('SENT') |
                (t.status.equals('FAILED') &
                    (t.nextRetryAfter.isNull() | t.nextRetryAfter.isSmallerOrEqualValue(now))),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<SyncOutboxData?> outboxRowById(String id) =>
      (select(syncOutbox)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> unsyncedOutboxCount() async {
    final rows = await (selectOnly(syncOutbox)
          ..addColumns([syncOutbox.id.count()])
          ..where(syncOutbox.status.isNotValue('ACKED')))
        .getSingle();
    return rows.read(syncOutbox.id.count()) ?? 0;
  }

  Future<List<SyncOutboxData>> unsyncedOutboxRows({int limit = 100}) {
    return (select(syncOutbox)
          ..where((t) => t.status.isNotValue('ACKED'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<void> patchOutbox(String id, SyncOutboxCompanion patch) =>
      (update(syncOutbox)..where((t) => t.id.equals(id))).write(patch);

  Future<void> insertInbox(SyncInboxCompanion row) => into(syncInbox).insert(row);

  Future<void> markInboxApplied(String id) =>
      (update(syncInbox)..where((t) => t.id.equals(id))).write(
        const SyncInboxCompanion(applied: Value(true)),
      );

  Future<bool> inboxHasEventId(String eventId) async {
    final q = select(syncInbox)..where((t) => t.eventId.equals(eventId))..limit(1);
    return (await q.get()).isNotEmpty;
  }

  Future<SyncInboxData?> inboxRowByEventId(String eventId) =>
      (select(syncInbox)..where((t) => t.eventId.equals(eventId))).getSingleOrNull();
}
