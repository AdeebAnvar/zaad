import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/dine_in_log/dine_in_reference_utils.dart';

void main() {
  group('DineInRefParser.dineInAnchorFromHubMetadata', () {
    test('reads top-level dine_in_anchor', () {
      final json = jsonEncode(<String, dynamic>{
        DineInRefParser.hubMetadataAnchorKey: '2|T5 | 3 pax',
      });
      expect(DineInRefParser.dineInAnchorFromHubMetadata(json), '2|T5 | 3 pax');
    });

    test('reads anchor from frozen snapshot envelope', () {
      final json = jsonEncode(<String, dynamic>{
        'snapshot': <String, dynamic>{
          'reference_number': '1|T3 | 2 pax',
          'order_type': 'dine_in',
        },
        'updatedAt': 1,
      });
      expect(DineInRefParser.dineInAnchorFromHubMetadata(json), '1|T3 | 2 pax');
    });

    test('reads anchor from metadata.flutter block', () {
      final json = jsonEncode(<String, dynamic>{
        'metadata': <String, dynamic>{
          'flutter': <String, dynamic>{
            'reference_number': '3|T9 | 4 pax',
          },
        },
      });
      expect(DineInRefParser.dineInAnchorFromHubMetadata(json), '3|T9 | 4 pax');
    });
  });

  group('DineInRefParser.dineInRoutingAnchorForMatching', () {
    test('staff KOT ref does not shadow hub dine_in_anchor', () {
      final o = Order(
        id: 2,
        cartId: 1,
        invoiceNumber: 'INV-1-002',
        referenceNumber: 'ead',
        totalAmount: 10,
        discountAmount: 0,
        finalAmount: 10,
        cashAmount: 0,
        creditAmount: 0,
        cardAmount: 0,
        onlineAmount: 0,
        createdAt: DateTime.utc(2026, 5, 17),
        status: 'kot',
        orderType: 'dine_in',
        branchId: 1,
        hubSyncPending: false,
        hubMetadata: jsonEncode(<String, dynamic>{
          DineInRefParser.hubMetadataAnchorKey: '1|1 | 2 pax',
        }),
      );
      expect(DineInRefParser.dineInRoutingAnchorForMatching(o), '1|1 | 2 pax');
      expect(
        DineInRefParser.orderMatchesFloorTable(
          o,
          1,
          '1',
          <String, Set<int>>{'1': {1}},
        ),
        isTrue,
      );
    });
  });

  group('DineInRefParser.routingAnchorFromLanSnapshot', () {
    test('reads dine_in_anchor from snapshot top level', () {
      final snap = <String, dynamic>{
        'dine_in_anchor': '2|T7 | 1 pax',
        'order_type': 'dine_in',
      };
      expect(DineInRefParser.routingAnchorFromLanSnapshot(snap), '2|T7 | 1 pax');
    });
  });

  group('DineInRefParser.orderMatchesFloorTable', () {
    test('matches floor-prefixed reference on order row', () {
      final o = Order(
        id: 1,
        cartId: 1,
        invoiceNumber: 'INV-1-010',
        referenceNumber: '1|T2 | 2 pax',
        totalAmount: 10,
        discountAmount: 0,
        finalAmount: 10,
        cashAmount: 0,
        creditAmount: 0,
        cardAmount: 0,
        onlineAmount: 0,
        createdAt: DateTime.utc(2026, 5, 17),
        status: 'kot',
        orderType: 'dine_in',
        branchId: 1,
        hubSyncPending: false,
      );
      expect(
        DineInRefParser.orderMatchesFloorTable(
          o,
          1,
          'T2',
          <String, Set<int>>{'T2': {1}},
        ),
        isTrue,
      );
    });
  });
}
