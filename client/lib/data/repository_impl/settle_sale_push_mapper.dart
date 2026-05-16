import 'dart:convert';

import 'package:pos/data/repository_impl/push_local_to_push_records_mapper.dart';
import 'package:pos/presentation/day_closing/day_closing_summary.dart';

/// One element of `push_records.settle_sales`.
///
/// Includes `category_wise_product_list` and `item_wise_product_list` as JSON arrays
/// (same shape as the day-closing screen / receipt sections 5–6).
class SettleSalePushMapper {
  SettleSalePushMapper._();

  static Map<String, dynamic> buildSettleSalePayload(
    DayClosingSummary s, {
    required String uuid,
    required int branchId,
    required int userId,
    required DateTime at,
    DayClosingCloseCashReconciliation? cashCloseReconciliation,
  }) {
    final orderTypeSummary = <String, dynamic>{};
    for (final row in s.typeRows) {
      final key = switch (row.type) {
        'DINE-IN' => 'dine_in',
        'DELIVERY' => 'delivery',
        'TAKEAWAY' => 'take_away',
        _ => row.type.toLowerCase().replaceAll('-', '_'),
      };
      orderTypeSummary[key] = <String, dynamic>{
        'amount': row.amount,
        'discount': row.discount,
        'count': row.count,
      };
    }

    final expense = s.purchase + s.salary;
    final ts = PushLocalToPushRecordsMapper.formatApiDateTime(at);

    final cashSaleForPayload = cashCloseReconciliation != null
        ? cashCloseReconciliation.actualCashSale
        : s.cashSale;
    final excessForPayload =
        cashCloseReconciliation != null ? cashCloseReconciliation.manualExcess : s.excessAmount;
    final shortForPayload =
        cashCloseReconciliation != null ? cashCloseReconciliation.manualShort : s.shortAmount;
    final cashInForPayload = cashCloseReconciliation != null
        ? (s.openingCash + cashCloseReconciliation.actualCashSale + s.otherIncome)
        : s.cashIn;
    final cashDrawerForPayload =
        cashCloseReconciliation != null ? (cashInForPayload - s.cashOut) : s.cashDrawer;

    final categoryWise = s.categoryRows
        .map(
          (r) => <String, dynamic>{
            'category': r.category,
            'qty': r.qty,
            'amount': r.amount,
          },
        )
        .toList();
    final itemWise = s.itemRows
        .map(
          (r) => <String, dynamic>{
            'item': r.item,
            'qty': r.qty,
            'amount': r.amount,
          },
        )
        .toList();

    return <String, dynamic>{
      'uuid': uuid,
      'branch_id': branchId,
      'user_id': userId,
      'cash_at_starting': s.openingCash,
      'cash_sale': cashSaleForPayload,
      'card_sale': s.cardSale,
      'credit_sale': s.creditSale,
      'delivery_sale': s.deliverySale,
      'online_order_recovery': s.onlineSale,
      'credit_recover': s.creditRecovery,
      'discount': s.discount,
      'net_total': s.netTotal,
      'cash_drawer': cashDrawerForPayload.toString(),
      'gross_total_tax': '0',
      'expense': expense.toString(),
      'pay_back': 0,
      'pay_back_vat': 0,
      'staff_id': null,
      'purchase': s.purchase,
      'other_income': s.otherIncome,
      'salary': s.salary,
      'creditrecovery_payment_wise': '[]',
      'outstanding_credit': s.outstandingCredit,
      'purchasePaymentWise': '[]',
      'expensepayment_wise': '[]',
      'cash_in': cashInForPayload,
      'cash_out': s.cashOut,
      'excess': excessForPayload,
      'short': shortForPayload,
      'order_type_summary': jsonEncode(orderTypeSummary),
      'category_wise_product_list': jsonEncode(categoryWise),
      'item_wise_product_list': jsonEncode(itemWise),
      'created_at': ts,
      'updated_at': ts,
    };
  }
}
