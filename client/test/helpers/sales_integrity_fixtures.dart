import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/data/local/drift_database.dart';

/// Seeds branch 2 + session for invoice/item integrity tests.
Future<void> seedBranch2Session(AppDatabase db, {int userId = 1}) async {
  final now = DateTime(2020, 1, 1);
  await db.into(db.branches).insert(
        BranchesCompanion.insert(
          id: const Value(2),
          branchName: 'Al NAHDA',
          location: '-',
          contactNo: '-',
          vat: 'no_vat',
          prefixInv: 'INV',
          invoiceHeader: 'Al NAHDA',
          image: '',
          installationDate: now,
          expiryDate: now,
          openingCash: 0,
        ),
      );
  await db.into(db.branches).insert(
        BranchesCompanion.insert(
          id: const Value(1),
          branchName: 'Other',
          location: '-',
          contactNo: '-',
          vat: 'no_vat',
          prefixInv: 'INV',
          invoiceHeader: 'Other',
          image: '',
          installationDate: now,
          expiryDate: now,
          openingCash: 0,
        ),
      );
  await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          id: const Value(10),
          name: 'Food',
          otherName: 'Food',
          branchId: const Value(2),
        ),
      );
  await db.into(db.users).insert(
        UsersCompanion.insert(
          id: Value(userId),
          branchId: 2,
          name: 'Cashier',
          usertype: 'staff',
          mobilePassword: '',
          permissions: '[]',
        ),
      );
  await db.sessionDao.saveSession(userId, 'counter', 2);
  await db.into(db.items).insert(
        ItemsCompanion.insert(
          id: const Value(100),
          name: 'Burger',
          otherName: 'Burger',
          sku: 'B1',
          price: 50,
          stock: 99,
          categoryName: 'Food',
          categoryOtherName: 'Food',
          barcode: '',
          categoryId: 10,
        ),
      );
  await db.into(db.items).insert(
        ItemsCompanion.insert(
          id: const Value(101),
          name: 'Tea',
          otherName: 'Tea',
          sku: 'T1',
          price: 10,
          stock: 99,
          categoryName: 'Food',
          categoryOtherName: 'Food',
          barcode: '',
          categoryId: 10,
        ),
      );
}

String hubMetadataItemsJson(List<Map<String, dynamic>> items) => jsonEncode(<String, dynamic>{
      'snapshot': <String, dynamic>{'items': items},
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

String orderLogJson({
  required int orderId,
  required List<Map<String, dynamic>> items,
}) =>
    jsonEncode(<String, dynamic>{
      'order_id': orderId,
      'items': items,
    });

Map<String, dynamic> lineSnapshot({
  required int itemId,
  required String name,
  int qty = 1,
  double total = 10,
}) =>
    <String, dynamic>{
      'item_id': itemId,
      'item_name': name,
      'quantity': qty,
      'total': total,
    };

/// Hub ORDER_CREATE / ORDER_UPDATE envelope body for [SyncInboxApplier].
Map<String, dynamic> hubOrderPayload({
  required String serverOrderId,
  required String invoice,
  required int branchId,
  required List<Map<String, dynamic>> items,
  double finalAmount = 10,
  String status = 'completed',
  String orderType = 'take_away',
  int updatedAtMs = 1000,
  DateTime? createdAt,
  String? dineInAnchor,
  String? referenceNumber,
}) {
  final snap = <String, dynamic>{
    'invoice_number': invoice,
    'branch_id': branchId,
    'status': status,
    'order_type': orderType,
    'created_at': (createdAt ?? DateTime.utc(2026, 5, 17, 12)).toIso8601String(),
    'final_amount': finalAmount,
    'total_amount': finalAmount,
    'items': items,
    if (referenceNumber != null) 'reference_number': referenceNumber,
    if (dineInAnchor != null) 'dine_in_anchor': dineInAnchor,
  };
  return <String, dynamic>{
    'orderId': serverOrderId,
    'updatedAt': updatedAtMs,
    'snapshot': snap,
  };
}

PosSyncEnvelope hubOrderEnvelope(Map<String, dynamic> payload) => PosSyncEnvelope(
      eventId: 'evt-${payload['orderId']}',
      type: PosSyncEventTypes.orderCreate,
      payload: payload,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      deviceId: 'test-device',
    );
