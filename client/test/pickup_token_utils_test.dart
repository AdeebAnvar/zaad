import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/pickup_token_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/branch_model.dart';

import 'helpers/sales_integrity_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pickup token allocation', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await seedBranch2Session(db);
    });

    tearDown(() async {
      await db.close();
    });

    BranchModel branchWithToken(int tokenNo) {
      final now = DateTime.utc(2026, 5, 30);
      return BranchModel(
        id: 2,
        branchName: 'Karama',
        location: 'Dubai',
        contactNo: '+971',
        email: null,
        socialMedia: null,
        vat: 'inclusive',
        vatPercent: 5,
        trnNumber: null,
        prefixInv: 'INV',
        invoiceHeader: 'Karama',
        image: '',
        installationDate: now,
        expiryDate: now.add(const Duration(days: 365)),
        openingCash: 0,
        lastTokenNo: tokenNo,
      );
    }

    test('starts at lastTokenNo + 1 when no local orders', () async {
      await db.branchesDao.insertBranches([branchWithToken(41)]);

      expect(await nextPickupTokenForBranch(db, 2), 42);
    });

    test('uses max(local order token, lastTokenNo) + 1', () async {
      await db.branchesDao.insertBranches([branchWithToken(41)]);
      final cartId = await db.cartsDao.createCart('INV-2-900', branchId: 2);
      await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-2-900',
          branchId: const Value(2),
          totalAmount: 10,
          finalAmount: 10,
          createdAt: DateTime.utc(2026, 5, 30, 12),
          pickupToken: const Value(55),
        ),
      );

      expect(await nextPickupTokenForBranch(db, 2), 56);
    });

    test('SUB COMPANY_SNAPSHOT branch seed flows through branches table', () async {
      await db.branchesDao.insertBranches([branchWithToken(99)]);

      final branch = await db.branchesDao.getBranchById(2);
      expect(branch?.lastTokenNo, 99);
      expect(await nextPickupTokenForBranch(db, 2), 100);
    });
  });
}
