import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/pricing/vat_inclusive_breakdown.dart';
import 'package:pos/core/utils/order_log_cart_fallback.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/features/orders/data/hub_orders_payload_builder.dart';
import 'package:pos/features/orders/data/order_push_status.dart';

Order _dummyOrder({
  int id = 1,
  int cartId = 10,
  String invoice = 'INV-T',
  double totalAmount = 100,
  double discountAmount = 0,
  String? discountType,
  double finalAmount = 100,
  double cash = 100,
  String status = 'completed',
  String? orderType = 'take_away',
  String? hubMetadata,
}) {
  return Order(
    id: id,
    cartId: cartId,
    invoiceNumber: invoice,
    totalAmount: totalAmount,
    discountAmount: discountAmount,
    discountType: discountType,
    finalAmount: finalAmount,
    cashAmount: cash,
    creditAmount: 0,
    cardAmount: 0,
    onlineAmount: 0,
    createdAt: DateTime.utc(2026, 5, 14, 12),
    status: status,
    orderType: orderType,
    branchId: 1,
    hubMetadata: hubMetadata,
    hubSyncPending: false,
  );
}

void main() {
  group('vatBreakdownFromInclusive', () {
    test('5% inclusive: 28 → net ~26.67, VAT ~1.33 (receipt math)', () {
      final r = vatBreakdownFromInclusive(28, vatMode: 'inclusive', vatPercentRaw: 5);
      expect(r.netBeforeVat, closeTo(26.6666666667, 0.02));
      expect(r.vatAmount, closeTo(1.3333333333, 0.02));
      expect(r.netBeforeVat + r.vatAmount, closeTo(28, 0.001));
    });

    test('no_vat returns full total as net', () {
      final r = vatBreakdownFromInclusive(100, vatMode: 'no_vat', vatPercentRaw: 5);
      expect(r.netBeforeVat, 100);
      expect(r.vatAmount, 0);
    });

    test('zero percent behaves like no VAT', () {
      final r = vatBreakdownFromInclusive(100, vatMode: 'standard', vatPercentRaw: 0);
      expect(r.vatAmount, 0);
      expect(r.netBeforeVat, 100);
    });

    test('parses string vatPercent', () {
      final r = vatBreakdownFromInclusive(21, vatMode: 'inclusive', vatPercentRaw: '5');
      expect(r.netBeforeVat + r.vatAmount, closeTo(21, 0.001));
    });
  });

  group('OrderLogCartFallback (LAN SUB snapshot hydration)', () {
    test('decode hub envelope snapshot.items totals', () {
      const envelope = '''
{"orderId":"srv-1","snapshot":{"invoice_number":"INV-4-034","items":[
  {"item_id":1,"item_name":"Normal","quantity":1,"total":7},
  {"item_id":2,"item_name":"Fresh Lime","quantity":1,"total":7}
],"total_amount":18,"final_amount":18,"created_at":"2026-05-14T12:00:00.000Z","status":"pending",
"metadata":{"flutter":{"total_amount":18,"final_amount":18}}},"updatedAt":1}
''';
      final lines = OrderLogCartFallback.decodeCartItemsFromPayloadJson(envelope, 99);
      expect(lines, hasLength(2));
      expect(lines.fold<double>(0, (a, c) => a + c.total), closeTo(14, 0.001));
      expect(lines[0].itemName, 'Normal');
      expect(lines[1].itemName, 'Fresh Lime');
    });

    test('decode alternate money keys (line_total / amount)', () {
      final raw = [
        {'item_name': 'A', 'quantity': 1, 'line_total': 10.0},
        {'item_name': 'B', 'qty': 2, 'amount': '11'},
      ];
      final lines = OrderLogCartFallback.decodeCartItemsFromItemsList(raw, 1);
      expect(lines, hasLength(2));
      expect(lines[0].total, closeTo(10, 0.001));
      expect(lines[1].total, closeTo(11, 0.001));
      expect(lines[1].quantity, 2);
    });

    test('unitPriceCents used when total missing', () {
      final raw = [
        {'item_name': 'Thaichill', 'quantity': 1, 'unit_price_cents': 700},
      ];
      final lines = OrderLogCartFallback.decodeCartItemsFromItemsList(raw, 1);
      expect(lines.single.total, closeTo(7, 0.001));
    });
  });

  group('HubOrdersPayloadBuilder (MAIN → hub wire)', () {
    test('buildJson totalCents matches finalAmount; cart_lines sum to line totals', () {
      final draft = _dummyOrder(
        totalAmount: 28,
        finalAmount: 28,
        cash: 28,
        discountAmount: 0,
      );
      final cartItems = [
        const CartItem(
          id: 1,
          cartId: 10,
          itemId: 101,
          itemName: 'Butterscotch',
          quantity: 1,
          total: 10,
          discount: 0,
        ),
        const CartItem(
          id: 2,
          cartId: 10,
          itemId: 102,
          itemName: 'Mango Passion',
          quantity: 1,
          total: 11,
          discount: 0,
        ),
        const CartItem(
          id: 3,
          cartId: 10,
          itemId: 103,
          itemName: 'Thaichill',
          quantity: 1,
          total: 7,
          discount: 0,
        ),
      ];
      final json = HubOrdersPayloadBuilder.buildJson(
        draft: draft,
        cartItems: cartItems,
        deviceUuid: 'dev',
        correlationId: 'corr',
      );
      expect(json['totalCents'], 2800);
      final meta = json['metadata'] as Map<String, dynamic>;
      final cartLines = meta['cart_lines'] as List<dynamic>;
      expect(cartLines, hasLength(3));
      var sum = 0.0;
      for (final e in cartLines) {
        sum += (e as Map<String, dynamic>)['total'] as num;
      }
      expect(sum, closeTo(28, 0.001));
      final items = json['items'] as List<dynamic>;
      expect((items.first as Map)['unitPriceCents'], 1000);
    });

    test('cartLinesToJson round-trips through snapshot decoder', () {
      final lines = [
        const CartItem(
          id: 5,
          cartId: 2,
          itemId: 9,
          itemName: 'X',
          quantity: 2,
          total: 18,
          discount: 0,
        ),
      ];
      final encoded = HubOrdersPayloadBuilder.cartLinesToJson(lines);
      final back = OrderLogCartFallback.decodeCartItemsFromItemsList(encoded, 2);
      expect(back.single.quantity, 2);
      expect(back.single.total, closeTo(18, 0.001));
      expect(back.single.itemName, 'X');
    });

    test('flutterBlockFromDraft carries amounts for hub metadata', () {
      final o = _dummyOrder(totalAmount: 30, finalAmount: 27, discountAmount: 3, discountType: 'amount');
      final f = HubOrdersPayloadBuilder.flutterBlockFromDraft(o);
      expect(f['total_amount'], 30);
      expect(f['final_amount'], 27);
      expect(f['discount_amount'], 3);
      expect(f['branch_id'], 1);
    });

    test('decodeEnvelopeMetadata parses hubMetadata wrapper', () {
      const hm = '{"orderId":"x","snapshot":{"invoice_number":"I1"}}';
      final m = HubOrdersPayloadBuilder.decodeEnvelopeMetadata(hm);
      expect(m, isNotNull);
      expect(m!['orderId'], 'x');
    });
  });

  group('OrderPushStatus (MAIN / SUB status mapping)', () {
    test('take_away completed maps to delivered on remote', () {
      expect(OrderPushStatus.toRemote(orderType: 'take_away', localStatus: 'completed'), 'delivered');
    });

    test('delivery completed maps to delivered', () {
      expect(OrderPushStatus.toRemote(orderType: 'delivery', localStatus: 'completed'), 'delivered');
    });

    test('localFromHub maps reject to cancelled for take_away', () {
      expect(OrderPushStatus.localFromHub(orderType: 'take_away', hubStatus: 'reject'), 'cancelled');
    });

    test('localFromHub maps delivered to completed for dine_in', () {
      expect(OrderPushStatus.localFromHub(orderType: 'dine_in', hubStatus: 'delivered'), 'completed');
    });

    test('incomingStatusShouldWin advances delivery lifecycle', () {
      expect(
        OrderPushStatus.incomingStatusShouldWin(
          currentLocal: 'pending',
          incomingMappedLocal: 'completed',
        ),
        isTrue,
      );
      expect(
        OrderPushStatus.incomingStatusShouldWin(
          currentLocal: 'completed',
          incomingMappedLocal: 'pending',
        ),
        isFalse,
      );
    });
  });

  group('Line list vs order header (regression: SUB dialog totals)', () {
    test('snapshot line sum can differ from flutter total_amount — decoder is faithful', () {
      const envelope = '''
{"orderId":"srv-2","snapshot":{"invoice_number":"INV-X","items":[
  {"item_name":"A","quantity":1,"total":7},
  {"item_name":"B","quantity":1,"total":7}
],"metadata":{"flutter":{"total_amount":18,"final_amount":18}}},"updatedAt":1}
''';
      final lines = OrderLogCartFallback.decodeCartItemsFromPayloadJson(envelope, 1);
      final sum = lines.fold<double>(0, (a, c) => a + c.total);
      final root = jsonDecode(envelope) as Map<String, dynamic>;
      final snap = root['snapshot'] as Map<String, dynamic>;
      final flutter = (snap['metadata'] as Map)['flutter'] as Map<String, dynamic>;
      final header = (flutter['final_amount'] as num).toDouble();
      expect(sum, closeTo(14, 0.001));
      expect(header, closeTo(18, 0.001));
      expect((header - sum).abs() > 0.5, isTrue);
    });
  });
}
