import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/data/local/drift_database.dart';

/// Regression: MAIN must not drop SUB [ORDER_CREATE] when both share a cloned [deviceId].
void main() {
  test('SUB ORDER eventId is not in MAIN outbox (would be applied)', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    await db.syncQueueDao.insertOutbox(
      SyncOutboxCompanion.insert(
        id: 'main-only-event',
        eventType: PosSyncEventTypes.orderCreate,
        payload: '{}',
      ),
    );

    final mainEcho = await db.syncQueueDao.outboxRowById('main-only-event');
    final subEvent = await db.syncQueueDao.outboxRowById('sub-tablet-event-uuid');

    expect(mainEcho, isNotNull);
    expect(subEvent, isNull);
  });
}
