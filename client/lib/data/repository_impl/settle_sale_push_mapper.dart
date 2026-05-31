import 'dart:convert';

import 'package:pos/data/repository_impl/push_local_to_push_records_mapper.dart';
import 'package:pos/presentation/day_closing/day_closing_summary.dart';

/// One element of `push_records.settle_sales`.
///
/// Includes `category_wise_product_list` as a JSON array (day-closing section 5).
class SettleSalePushMapper {
  SettleSalePushMapper._();

  static Map<String, dynamic> buildSettleSalePayload(
    DayClosingSummary s, {
    required String uuid,
    required int branchId,
    required int userId,
    required DateTime at,
    DayClosingCloseReconciliation? closeReconciliation,
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

    final recon = closeReconciliation;
    final cashSaleForPayload = recon?.actualCash ?? s.cashSale;
    final cardSaleForPayload = recon?.actualCard ?? s.cardSale;
    final creditSaleForPayload = recon?.actualCredit ?? s.creditSale;
    final onlineSaleForPayload = recon?.actualOnline ?? s.onlineSale;
    final excessForPayload = recon?.totalExcess ?? s.excessAmount;
    final shortForPayload = recon?.totalShort ?? s.shortAmount;
    final cashInForPayload = recon != null
        ? (s.openingCash + recon.actualCash + s.otherIncome)
        : s.cashIn;
    final cashDrawerForPayload =
        recon != null ? (cashInForPayload - s.cashOut) : s.cashDrawer;

    final categoryWise = s.categoryRows
        .map(
          (r) => <String, dynamic>{
            'category': r.category,
            'qty': r.qty,
            'amount': r.amount,
          },
        )
        .toList();

    final paymentReconciliation = recon == null
        ? null
        : [
            for (final v in recon.paymentVariances)
              <String, dynamic>{
                'channel': v.channel.toLowerCase(),
                'excess': v.excess,
                'short': v.short,
              },
          ];

    return <String, dynamic>{
      'uuid': uuid,
      'branch_id': branchId,
      'user_id': userId,
      'cash_at_starting': s.openingCash,
      'cash_sale': cashSaleForPayload,
      'card_sale': cardSaleForPayload,
      'credit_sale': creditSaleForPayload,
      'delivery_sale': s.deliverySale,
      'online_order_recovery': onlineSaleForPayload,
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
      if (paymentReconciliation != null)
        'payment_reconciliation': jsonEncode(paymentReconciliation),
      'order_type_summary': jsonEncode(orderTypeSummary),
      'category_wise_product_list': jsonEncode(categoryWise),
      'created_at': ts,
      'updated_at': ts,
    };
  }
}
