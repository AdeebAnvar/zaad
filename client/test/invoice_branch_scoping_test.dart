import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/invoice_counter_seed.dart';
import 'package:pos/core/utils/invoice_number_utils.dart';
import 'package:pos/domain/models/branch_model.dart';
import 'package:pos/core/utils/json_int_parse.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository_impl/order_repository_impl.dart';
import 'package:pos/domain/models/user_model.dart';
import 'helpers/sales_integrity_fixtures.dart';

void main() {
  group('parseBranchScopedInvoice / last_receipt', () {
    test('parses INV-4-1155', () {
      final p = parseBranchScopedInvoice('INV-4-1155');
      expect(p?.prefix, 'INV');
      expect(p?.branchId, 4);
      expect(p?.suffix, 1155);
    });

    test('null last_receipt starts from 001', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await seedBranch2Session(db);
      final repo = OrderRepositoryImpl(db);
      final r = await repo.createCartWithReservedInvoice(orderType: 'take_away');
      expect(r.invoice, 'INV-2-001');
    });

    test('last_receipt INV-4-1110 next sale is INV-4-1111', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final now = DateTime(2020, 1, 1);
      await db.into(db.branches).insert(
            BranchesCompanion.insert(
              id: const Value(4),
              branchName: 'Branch 4',
              location: '-',
              contactNo: '-',
              vat: 'no_vat',
              prefixInv: 'INV',
              invoiceHeader: 'B4',
              image: '',
              installationDate: now,
              expiryDate: now,
              openingCash: 0,
            ),
          );
      await db.sessionDao.saveSession(1, 'counter', 4);

      await seedInvoiceCounterForBranchIfNeeded(
        db,
        BranchModel(
          id: 4,
          branchName: 'Branch 4',
          location: '-',
          contactNo: '-',
          email: null,
          socialMedia: null,
          vat: 'no_vat',
          vatPercent: null,
          trnNumber: null,
          prefixInv: 'INV',
          invoiceHeader: 'B4',
          image: '',
          installationDate: now,
          expiryDate: now,
          openingCash: 0,
          lastReceipt: 'INV-4-1110',
        ),
      );

      final repo = OrderRepositoryImpl(db);
      final r = await repo.createCartWithReservedInvoice(orderType: 'take_away');
      expect(r.invoice, 'INV-4-1111');
    });

    test('after bootstrap last_receipt next sale is suffix + 1', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final now = DateTime(2020, 1, 1);
      await db.into(db.branches).insert(
            BranchesCompanion.insert(
              id: const Value(4),
              branchName: 'Branch 4',
              location: '-',
              contactNo: '-',
              vat: 'no_vat',
              prefixInv: 'INV',
              invoiceHeader: 'B4',
              image: '',
              installationDate: now,
              expiryDate: now,
              openingCash: 0,
            ),
          );
      await db.sessionDao.saveSession(1, 'counter', 4);

      await seedInvoiceCounterForBranchIfNeeded(
        db,
        BranchModel(
          id: 4,
          branchName: 'Branch 4',
          location: '-',
          contactNo: '-',
          email: null,
          socialMedia: null,
          vat: 'no_vat',
          vatPercent: null,
          trnNumber: null,
          prefixInv: 'INV',
          invoiceHeader: 'B4',
          image: '',
          installationDate: now,
          expiryDate: now,
          openingCash: 0,
          lastReceipt: 'INV-4-1155',
        ),
      );

      final repo = OrderRepositoryImpl(db);
      final r = await repo.createCartWithReservedInvoice(orderType: 'take_away');
      expect(r.invoice, 'INV-4-1156');
    });
  });

  group('formatShortInvoice', () {
    test('uses explicit branch digit in label', () {
      expect(formatShortInvoice('INV', 2, 5), 'INV-2-005');
      expect(formatShortInvoice('INV', 2, 1), 'INV-2-001');
      expect(formatShortInvoice('CAF', 3, 12), 'CAF-3-012');
    });

    test('rejects non-positive branchId (old 0→1 bug)', () {
      expect(() => formatShortInvoice('INV', 0, 1), throwsArgumentError);
      expect(() => formatShortInvoice('INV', -1, 1), throwsArgumentError);
    });
  });

  group('login / API branch parsing', () {
    test('branchIdFromUserJson returns 0 when branch missing', () {
      expect(branchIdFromUserJson({}), 0);
      expect(branchIdFromUserJson({'branch_id': null}), 0);
      expect(branchIdFromUserJson({'branch_id': '0'}), 0);
    });

    test('UserModel.fromJson accepts string and nested branch', () {
      expect(
        UserModel.fromJson({'id': 1, 'branch_id': '2', 'name': 'A', 'usertype': 'staff'}).branchId,
        2,
      );
      expect(
        UserModel.fromJson({
          'id': 1,
          'branch': {'id': 2},
          'name': 'A',
          'usertype': 'staff',
        }).branchId,
        2,
      );
    });

    test('parseIntLoose handles int, num, and string', () {
      expect(parseIntLoose(2), 2);
      expect(parseIntLoose(2.9), 3);
      expect(parseIntLoose('2'), 2);
      expect(parseIntLoose(''), isNull);
      expect(parseIntLoose(null), isNull);
    });
  });

  group('resolveMirroredOrderBranchId (hub sync)', () {
    test('prefers snapshot branch over session', () {
      expect(
        resolveMirroredOrderBranchId(snap: {'branch_id': 2}, sessionBranchId: 1),
        2,
      );
      expect(
        resolveMirroredOrderBranchId(
          snap: const {},
          flutterSnap: {'branchId': 3},
          sessionBranchId: 1,
        ),
        3,
      );
    });

    test('falls back to session when snapshot empty', () {
      expect(
        resolveMirroredOrderBranchId(snap: const {}, sessionBranchId: 2),
        2,
      );
    });

    test('returns 0 when neither snapshot nor session valid', () {
      expect(
        resolveMirroredOrderBranchId(snap: const {}, sessionBranchId: 0),
        0,
      );
      expect(resolveMirroredOrderBranchId(snap: const {}), 0);
    });
  });

  group('session branch (requireActiveBranchId)', () {
    test('throws without session', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      expect(() => db.sessionDao.requireActiveBranchId(), throwsA(isA<StateError>()));
    });

    test('repairs session branch 0 from logged-in user branch', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await seedBranch2Session(db);
      await (db.update(db.sessions)).write(const SessionsCompanion(branchId: Value(0)));
      expect(await db.sessionDao.requireActiveBranchId(), 2);
      final row = await db.sessionDao.getActiveSession();
      expect(row?.branchId, 2);
    });

    test('throws when session branch is 0 and user branch missing', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await db.into(db.sessions).insert(
            SessionsCompanion.insert(userId: 1, role: 'counter', branchId: const Value(0)),
          );
      expect(() => db.sessionDao.requireActiveBranchId(), throwsA(isA<StateError>()));
    });

    test('returns branch 2 when session valid', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await db.sessionDao.saveSession(1, 'counter', 2);
      expect(await db.sessionDao.requireActiveBranchId(), 2);
    });
  });

  group('OrderRepositoryImpl invoice allocation', () {
    late AppDatabase db;
    late OrderRepositoryImpl repo;

    setUp(() async {
      db = AppDatabase.memory();
      await seedBranch2Session(db);
      repo = OrderRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('createDraftCart does not consume invoice sequence', () async {
      await repo.createDraftCart(orderType: 'take_away');
      await repo.createDraftCart(orderType: 'take_away');
      final r = await repo.createCartWithReservedInvoice(orderType: 'take_away');
      expect(r.invoice, 'INV-2-001');
    });

    test('reserved invoices are INV-2-001, INV-2-002', () async {
      final a = await repo.createCartWithReservedInvoice(orderType: 'take_away');
      final b = await repo.createCartWithReservedInvoice(orderType: 'take_away');
      expect(a.invoice, 'INV-2-001');
      expect(b.invoice, 'INV-2-002');
      expect(a.invoice.startsWith('INV-1-'), isFalse);
    });

    test('cart row stores session branchId 2', () async {
      final r = await repo.createCartWithReservedInvoice(orderType: 'take_away');
      final cart = await db.cartsDao.getCartByCartId(r.cartId);
      expect(cart?.branchId, 2);
    });

    test('createOrder persists orders.branchId from session not draft', () async {
      final r = await repo.createCartWithReservedInvoice(orderType: 'take_away');
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: r.cartId,
              itemId: 100,
              quantity: 1,
              total: const Value(10),
              itemName: const Value('Item'),
            ),
          );

      final id = await repo.createOrder(
        Order(
          id: 0,
          cartId: r.cartId,
          invoiceNumber: r.invoice,
          totalAmount: 10,
          discountAmount: 0,
          finalAmount: 10,
          cashAmount: 10,
          creditAmount: 0,
          cardAmount: 0,
          onlineAmount: 0,
          createdAt: DateTime.utc(2026, 5, 17),
          status: 'completed',
          orderType: 'take_away',
          branchId: 1,
          hubSyncPending: false,
        ),
      );

      final saved = (await db.ordersDao.getOrderById(id))!;
      expect(saved.branchId, 2);
      expect(saved.invoiceNumber, startsWith('INV-2-'));
    });

    test('branch 1 session allocates INV-1-* separately from branch 2', () async {
      await db.sessionDao.saveSession(1, 'counter', 1);
      final branch1 = await repo.createCartWithReservedInvoice(orderType: 'take_away');
      await db.sessionDao.saveSession(1, 'counter', 2);
      final branch2 = await repo.createCartWithReservedInvoice(orderType: 'take_away');

      expect(branch1.invoice, 'INV-1-001');
      expect(branch2.invoice, 'INV-2-001');
    });
  });
}
