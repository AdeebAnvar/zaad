import 'dart:convert';

import 'package:pos/data/local/drift_database.dart';
import 'package:pos/features/orders/data/order_push_status.dart';

/// Builds order JSON snapshots (line items + Flutter customer/payment block) for local logs / APIs.
class HubOrdersPayloadBuilder {
  static Map<String, dynamic> buildJson({
    required Order draft,
    required List<CartItem> cartItems,
    required String deviceUuid,
    required String correlationId,
  }) {
    final flutter = flutterBlockFromDraft(draft)
      ..['correlation_id'] = correlationId;

    final items = <Map<String, dynamic>>[];
    for (final line in cartItems) {
      final qty = line.quantity <= 0 ? 1 : line.quantity;
      final unitCents = ((line.total / qty) * 100).round();
      items.add({
        'sku': line.itemId.toString(),
        'name': line.itemName,
        'qty': qty,
        'unitPriceCents': unitCents,
        'taxCents': 0,
      });
    }

    final payments = <Map<String, dynamic>>[];
    void addPay(String method, double amount) {
      if (amount <= 0.004) return;
      payments.add({
        'method': method,
        'amountCents': (amount * 100).round(),
      });
    }

    addPay('cash', draft.cashAmount);
    addPay('credit', draft.creditAmount);
    addPay('card', draft.cardAmount);
    addPay('online', draft.onlineAmount);

    return <String, dynamic>{
      'status': OrderPushStatus.toRemote(orderType: draft.orderType, localStatus: draft.status),
      'totalCents': (draft.finalAmount * 100).round(),
      'items': items,
      'payments': payments,
      'metadata': <String, dynamic>{
        'flutter': flutter,
        'cart_lines': cartItems.map(_lineToJson).toList(),
      },
      'device': <String, dynamic>{
        'id': deviceUuid,
        'name': 'pos-flutter',
        'platform': 'flutter',
      },
    };
  }

  /// PATCH `/orders/:id` (`patchOrder` reads `status`, `totalCents`, shallow-merge `metadata`).
  static Map<String, dynamic> patchBodyFromDraft({
    required Order draft,
    required List<CartItem> cartItems,
  }) {
    return <String, dynamic>{
      'status': OrderPushStatus.toRemote(orderType: draft.orderType, localStatus: draft.status),
      'totalCents': (draft.finalAmount * 100).round(),
      'metadata': <String, dynamic>{
        'flutter': flutterBlockFromDraft(draft),
        'cart_lines': cartItems.map(_lineToJson).toList(),
      },
    };
  }

  static Map<String, dynamic> flutterBlockFromDraft(Order draft) => <String, dynamic>{
        'cart_id': draft.cartId,
        'total_amount': draft.totalAmount,
        'discount_amount': draft.discountAmount,
        'discount_type': draft.discountType,
        'final_amount': draft.finalAmount,
        'customer_name': draft.customerName,
        'customer_email': draft.customerEmail,
        'customer_phone': draft.customerPhone,
        'customer_gender': draft.customerGender,
        'cash_amount': draft.cashAmount,
        'credit_amount': draft.creditAmount,
        'card_amount': draft.cardAmount,
        'online_amount': draft.onlineAmount,
        'reference_number': draft.referenceNumber,
        'delivery_partner': draft.deliveryPartner,
        'driver_id': draft.driverId,
        'driver_name': draft.driverName,
        'user_id': draft.userId,
        'order_type': draft.orderType,
      };

  static List<Map<String, dynamic>> cartLinesToJson(List<CartItem> cartItems) =>
      cartItems.map(_lineToJson).toList();

  static Map<String, dynamic> _lineToJson(CartItem c) {
    return {
      'id': c.id,
      'cart_id': c.cartId,
      'item_id': c.itemId,
      'item_name': c.itemName,
      'item_variant_id': c.itemVariantId,
      'item_topping_id': c.itemToppingId,
      'quantity': c.quantity,
      'total': c.total,
      'discount': c.discount,
      'discount_type': c.discountType,
      'notes': c.notes,
    };
  }

  static Map<String, dynamic>? decodeEnvelopeMetadata(String? hubMetadataJson) {
    if (hubMetadataJson == null || hubMetadataJson.isEmpty) return null;
    try {
      final root = jsonDecode(hubMetadataJson);
      if (root is! Map<String, dynamic>) return null;
      return root;
    } catch (_) {
      return null;
    }
  }
}
