import 'package:intl/intl.dart';
import 'package:pos/features/orders/data/order_push_status.dart';

/// Maps local order log JSON ([OrderRepositoryImpl] snapshot) to `push_records` sale objects.
class PushLocalToPushRecordsMapper {
  PushLocalToPushRecordsMapper._();

  static const double _kCreditEpsilon = 0.004;

  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd HH:mm:ss');

  static String formatApiDateTime(DateTime dt) => _apiDate.format(dt.toLocal());

  /// Credit portion for [push_records] (`credit_sales` + `payment_status`).
  ///
  /// Prefer persisted [credit_amount]. If it is absent or ~zero but the tendered
  /// amounts don't cover [final_amount], infer the unpaid balance so we still
  /// emit a `credit_sales` row (matches invoices where credit wasn't split correctly).
  static double resolvedCreditAmount(Map<String, dynamic> snap) {
    final explicit = _toDouble(snap['credit_amount']);
    if (explicit > _kCreditEpsilon) return explicit;
    final net = _toDouble(snap['final_amount']);
    final tendered =
        _toDouble(snap['cash_amount']) + _toDouble(snap['card_amount']) + _toDouble(snap['online_amount']);
    final inferred = (net - tendered).clamp(0.0, double.infinity);
    return inferred > _kCreditEpsilon ? inferred : explicit;
  }

  static Map<String, dynamic> buildSale({
    required Map<String, dynamic> snap,
    required String saleUuid,
    required int branchId,
    required int userId,
    required int defaultPaymentTypeId,
    required int cashPaymentTypeId,
    required int cardPaymentTypeId,
    required int onlinePaymentTypeId,
    String? customerUuid,
  }) {
    final created = _parseDate(snap['created_at']) ?? DateTime.now();
    final updated = created;

    final orderType = _normalizeOrderType(snap['order_type']?.toString());
    final status = OrderPushStatus.toRemote(
      orderType: snap['order_type']?.toString(),
      localStatus: snap['status']?.toString(),
    );
    final invoice = snap['invoice_number']?.toString() ?? '';
    final ref = snap['reference_number'];
    final refNum = ref == null ? null : int.tryParse(ref.toString());

    final cash = _toDouble(snap['cash_amount']);
    final card = _toDouble(snap['card_amount']);
    final credit = resolvedCreditAmount(snap);
    final online = _toDouble(snap['online_amount']);
    final discountAmount = _toDouble(snap['discount_amount']);
    final discountType = snap['discount_type']?.toString();
    final discountPercent = discountType == 'percentage' ? discountAmount : 0.0;
    final discountInAmount = discountType != 'percentage' ? discountAmount : 0.0;

    final gross = _toDouble(snap['total_amount']);
    final net = _toDouble(snap['final_amount']);
    final taxAmt = (gross - net).clamp(0.0, double.infinity);

    final primaryPaymentTypeId = _pickPrimaryPaymentTypeId(
      cash: cash,
      card: card,
      online: online,
      credit: credit,
      defaultId: defaultPaymentTypeId,
      cashId: cashPaymentTypeId,
      cardId: cardPaymentTypeId,
      onlineId: onlinePaymentTypeId,
    );

    final paymentStatus = credit > _kCreditEpsilon ? 'unpaid' : 'paid';

    final items = _buildItems(
      snap['items'],
      createdAt: created,
      updatedAt: updated,
    );

    final nonCreditPaid = (net - credit).clamp(0.0, double.infinity);
    final payments = _buildPayments(
      cash: cash,
      card: card,
      online: online,
      fallbackAmount: nonCreditPaid,
      createdAt: created,
      updatedAt: updated,
      cashId: cashPaymentTypeId,
      cardId: cardPaymentTypeId,
      onlineId: onlinePaymentTypeId,
      defaultId: defaultPaymentTypeId,
    );

    final driverId = snap['driver_id'] as int?;
    // floor/table/waiter: extend snapshot when dine-in metadata is persisted locally.

    return <String, dynamic>{
      'uuid': saleUuid,
      'receipt_id': invoice,
      'user_id': (snap['user_id'] as int?) ?? userId,
      'branch_id': branchId,
      'customer_uuid': customerUuid,
      'order_type': orderType,
      'payment_type_id': primaryPaymentTypeId,
      'payment_status': paymentStatus,
      'status': status,
      'discount_in_amount': discountInAmount,
      'discount_in_percent': discountPercent,
      'amount_given': net,
      'balance_amount': 0.0,
      'gross_amount': gross,
      'tax_amount': taxAmt,
      'net_amount': net,
      if (refNum != null) 'referenceNumber': refNum,
      'created_at': formatApiDateTime(created),
      'updated_at': formatApiDateTime(updated),
      if (orderType == 'delivery' && driverId != null) 'driver_id': driverId,
      'items': items,
      'payments': payments,
    };
  }

  static Map<String, dynamic>? buildCreditForSale({
    required String creditUuid,
    required String saleUuid,
    required double creditAmount,
    required int branchId,
    required int userId,
    String? customerUuid,
    required DateTime created,
  }) {
    if (creditAmount <= _kCreditEpsilon) return null;
    return <String, dynamic>{
      'uuid': creditUuid,
      'customer_uuid': customerUuid,
      'type': 'credit',
      'amount': creditAmount,
      'payment_type_id': null,
      'sale_order_uuid': saleUuid,
      'user_id': userId,
      'branch_id': branchId,
      'created_at': formatApiDateTime(created),
      'updated_at': formatApiDateTime(created),
    };
  }

  static List<Map<String, dynamic>> _buildItems(
    dynamic raw, {
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final itemId = m['item_id'] as int? ?? 0;
      final toppingId = m['item_topping_id'] as int?;
      final qty = (m['quantity'] as int?) ?? 1;
      final total = _toDouble(m['total']);
      final disc = _toDouble(m['discount']);
      final discType = m['discount_type']?.toString();
      final discPct = discType == 'percentage' ? disc : 0.0;
      final discAmt = discType != 'percentage' ? disc : 0.0;
      final unitNet = qty > 0 ? total / qty : total;
      final unitGross = qty > 0 ? (total + discAmt) / qty : total + discAmt;

      final prePriceId = (m['price_id'] as num?)?.toInt();

      final toppings = <Map<String, dynamic>>[];
      if (toppingId != null && toppingId > 0) {
        toppings.add({
          'topping_id': toppingId,
          'price': unitNet,
          'qty': qty,
          'created_at': formatApiDateTime(createdAt),
          'updated_at': formatApiDateTime(updatedAt),
        });
      }

      out.add({
        'item_id': itemId,
        if ((m['item_name'] ?? '').toString().trim().isNotEmpty)
          'item_name': m['item_name'].toString().trim(),
        // `price_id` = server `itemprice.id`; normally set in [PushRecordsRepositoryImpl._enrichSaleLineItemsForPush].
        if (prePriceId != null && prePriceId > 0) 'price_id': prePriceId,
        'price': unitGross,
        'item_unit_price': unitNet,
        'discount_percent': discPct,
        'discount_amount': discAmt,
        'qty': qty,
        'total_price': total,
        'tax_amt': 0.0,
        'created_at': formatApiDateTime(createdAt),
        'updated_at': formatApiDateTime(updatedAt),
        'toppings': toppings,
      });
    }
    return out;
  }

  static List<Map<String, dynamic>> _buildPayments({
    required double cash,
    required double card,
    required double online,
    required double fallbackAmount,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int cashId,
    required int cardId,
    required int onlineId,
    required int defaultId,
  }) {
    final list = <Map<String, dynamic>>[];
    void add(int typeId, double amt) {
      if (amt <= _kCreditEpsilon) return;
      list.add({
        'payment_type_id': typeId.toString(),
        'amount': amt,
        'created_at': formatApiDateTime(createdAt),
        'updated_at': formatApiDateTime(updatedAt),
      });
    }

    add(cashId, cash);
    add(cardId, card);
    add(onlineId, online);
    if (list.isEmpty && fallbackAmount > _kCreditEpsilon) {
      add(defaultId, fallbackAmount);
    }
    return list;
  }

  static int _pickPrimaryPaymentTypeId({
    required double cash,
    required double card,
    required double online,
    required double credit,
    required int defaultId,
    required int cashId,
    required int cardId,
    required int onlineId,
  }) {
    if (cash >= card && cash >= online && cash > _kCreditEpsilon) return cashId;
    if (card >= online && card > _kCreditEpsilon) return cardId;
    if (online > _kCreditEpsilon) return onlineId;
    if (credit > _kCreditEpsilon) return defaultId;
    return defaultId;
  }

  static String _normalizeOrderType(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s == 'delivery') return 'delivery';
    if (s == 'dine_in' || s == 'dine-in') return 'dine_in';
    if (s == 'counter_sale' || s == 'counter') return 'take_away';
    return 'take_away';
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
