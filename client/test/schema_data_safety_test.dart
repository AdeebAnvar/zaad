import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pos/app/app_startup.dart';
import 'package:pos/core/utils/sqlite_file_backup.dart';
import 'package:pos/data/local/drift_database.dart';

import 'helpers/sales_integrity_fixtures.dart';

/// Data-safety: schema bumps must not wipe sales; WAL backups must pass quick_check.
void main() {
  group('SchemaStartupOutcome', () {
    test('syncSchemaVersionMetadata never deletes database files', () async {
      final temp = await Directory.systemTemp.createTemp('zaad_schema_meta_');
      final dbFile = File(p.join(temp.path, 'pos.sqlite'));
      await dbFile.writeAsString('placeholder', flush: true);
      await File(p.join(temp.path, 'data_schema_version.txt')).writeAsString('db_v51');

      final outcome = await AppStartup.syncSchemaVersionMetadata(
        localDir: temp,
        schemaVersion: 52,
      );

      expect(outcome.databaseFilesDeleted, isFalse);
      expect(outcome.schemaChanged, isTrue);
      expect(outcome.currentLabel, 'db_v52');
      expect(await dbFile.exists(), isTrue);
      expect(await File(p.join(temp.path, 'data_schema_version.txt')).readAsString(), 'db_v52');
    });
  });

  group('AppDatabase.file', () {
    late Directory temp;
    late File dbFile;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('zaad_schema_file_');
      dbFile = File(p.join(temp.path, 'pos.sqlite'));
    });

    tearDown(() async {
      try {
        await temp.delete(recursive: true);
      } catch (_) {}
    });

    Future<int> _seedOneOrder(AppDatabase database) async {
      await seedBranch2Session(database);
      final cartId = await database.cartsDao.createCart('INV-SAFE-1', branchId: 2);
      return database.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-SAFE-1',
          branchId: const Value(2),
          totalAmount: 100,
          finalAmount: 100,
          createdAt: DateTime(2024, 6, 1, 12),
          status: const Value('completed'),
        ),
      );
    }

    test('reopen preserves orders after close', () async {
      final db1 = AppDatabase.file(dbFile);
      final orderId = await _seedOneOrder(db1);
      expect(orderId, greaterThan(0));
      await db1.close();

      final db2 = AppDatabase.file(dbFile);
      final orders = await db2.ordersDao.getAllOrders(branchId: 2);
      expect(orders, hasLength(1));
      expect(orders.first.invoiceNumber, 'INV-SAFE-1');
      await db2.close();
    });

    test('ensureCompatibleLocalData keeps orders when schema label changes', () async {
      final db1 = AppDatabase.file(dbFile);
      await _seedOneOrder(db1);
      await db1.close();

      await File(p.join(temp.path, 'data_schema_version.txt')).writeAsString('db_v51');

      final db2 = AppDatabase.file(dbFile);
      final startup = AppStartup(db2);
      await startup.ensureCompatibleLocalData(localDirOverride: temp);
      expect(await dbFile.exists(), isTrue);
      final orders = await db2.ordersDao.getAllOrders(branchId: 2);
      expect(orders, hasLength(1));
      await db2.close();
    });
  });

  group('SqliteFileBackup', () {
    late Directory temp;
    late File dbFile;
    late AppDatabase db;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('zaad_backup_');
      dbFile = File(p.join(temp.path, 'pos.sqlite'));
      db = AppDatabase.file(dbFile);
      await seedBranch2Session(db);
      final cartId = await db.cartsDao.createCart('INV-BK', branchId: 2);
      await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-BK',
          branchId: const Value(2),
          totalAmount: 25,
          finalAmount: 25,
          createdAt: DateTime(2024, 8, 1),
          status: const Value('completed'),
        ),
      );
    });

    tearDown(() async {
      await db.close();
      try {
        await temp.delete(recursive: true);
      } catch (_) {}
    });

    test('backup after WAL checkpoint passes quick_check', () async {
      final target = File(p.join(temp.path, 'backup_test.db'));
      await SqliteFileBackup.copyWithWalCheckpoint(
        db: db,
        sourceDbFile: dbFile,
        targetFile: target,
      );
      expect(SqliteFileBackup.quickCheckOk(target), isTrue);
      expect(SqliteFileBackup.quickCheckOk(dbFile), isTrue);
    });

    test('backup file opens and contains the order row', () async {
      final target = File(p.join(temp.path, 'backup_manual.db'));
      await SqliteFileBackup.copyWithWalCheckpoint(
        db: db,
        sourceDbFile: dbFile,
        targetFile: target,
      );
      expect(SqliteFileBackup.quickCheckOk(target), isTrue);
      // Close live DB before opening backup copy (avoids Drift multi-instance warning).
      await db.close();
      final backupDb = AppDatabase.file(target);
      try {
        final orders = await backupDb.ordersDao.getAllOrders(branchId: 2);
        expect(orders, hasLength(1));
        expect(orders.first.invoiceNumber, 'INV-BK');
      } finally {
        await backupDb.close();
      }
      db = AppDatabase.file(dbFile);
    });
  });
}
