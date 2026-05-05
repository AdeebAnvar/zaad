import 'dart:convert';

import 'package:pos/data/repository_impl/push_local_to_push_records_mapper.dart';
import 'package:pos/presentation/day_closing/day_closing_summary.dart';

/// One element of `push_records.settle_sales`.
class SettleSalePushMapper {
  SettleSalePushMapper._();

  static Map<String, dynamic> buildSettleSalePayload(
    DayClosingSummary s, {
    required String uuid,
    required int branchId,
    required int userId,
    required DateTime at,
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

    return <String, dynamic>{
      'uuid': uuid,
      'branch_id': branchId,
      'user_id': userId,
      'cash_at_starting': s.openingCash,
      'cash_sale': s.cashSale,
      'card_sale': s.cardSale,
      'credit_sale': s.creditSale,
      'delivery_sale': s.deliverySale,
      'online_order_recovery': s.onlineSale,
      'credit_recover': s.creditRecovery,
      'discount': s.discount,
      'net_total': s.netTotal,
      'cash_drawer': s.cashDrawer.toString(),
      'gross_total_tax': '0',
      'expense': expense.toString(),
      'pay_back': 0,
      'pay_back_vat': 0,
      'staff_id': null,
      'purchase': s.purchase,
      'creditrecovery_payment_wise': '[]',
      'outstanding_credit': s.outstandingCredit,
      'purchasePaymentWise': '[]',
      'expensepayment_wise': '[]',
      'cash_in': s.cashIn,
      'cash_out': s.cashOut,
      'excess': s.excessAmount,
      'short': s.shortAmount,
      'order_type_summary': jsonEncode(orderTypeSummary),
      'created_at': ts,
      'updated_at': ts,
    };
  }
}
