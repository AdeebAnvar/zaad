import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/domain/models/user_model.dart';

void main() {
  group('CounterAccess', () {
    test('admin bypasses all checks', () {
      const access = CounterAccess.admin();
      expect(access.canPayment, isTrue);
      expect(access.canKotPrint, isTrue);
      expect(access.canInvoicePrint, isTrue);
      expect(access.canRecentSales, isTrue);
    });

    test('maps backend sale and log keys', () {
      final access = CounterAccess.fromUser(UserModel(
        id: 1,
        branchId: 1,
        name: 'c',
        usertype: 'counter',
        mobilePassword: '',
        permissions: const [
          'payment_p',
          'kot_print',
          'invoice_pr',
          'discount_item',
          'discount_invoice',
          'cash_only',
          'name',
          'number',
          'email',
          'gender',
          'customer_save',
          'recent_sal',
          'recent_sale_edit',
          'dine_in_lo',
          'dine_in_log_edit',
          'take_away_log_edit',
          'delivery_lo',
          'delivery_log_delete',
          'printer_set',
        ],
      ));

      expect(access.canPayment, isTrue);
      expect(access.canKotPrint, isTrue);
      expect(access.canInvoicePrint, isTrue);
      expect(access.canDiscountItem, isTrue);
      expect(access.canDiscountInvoice, isTrue);
      expect(access.canCashOnly, isTrue);
      expect(access.canCustomerName, isTrue);
      expect(access.canCustomerNumber, isTrue);
      expect(access.canCustomerEmail, isTrue);
      expect(access.canCustomerGender, isTrue);
      expect(access.canCustomer, isTrue);
      expect(access.canRecentSales, isTrue);
      expect(access.canRecentSaleEdit, isTrue);
      expect(access.canDineInLog, isTrue);
      expect(access.canDineInLogEdit, isTrue);
      expect(access.canTakeAwayLogEdit, isTrue);
      expect(access.canDeliveryLog, isTrue);
      expect(access.canDeliveryLogDelete, isTrue);
      expect(access.canPrinterSettings, isTrue);
      expect(access.canCashPay, isTrue);
      expect(access.canCardPay, isFalse);
      expect(access.canCreditPay, isFalse);
    });

    test('denies when permission omitted', () {
      final access = CounterAccess.fromUser(UserModel(
        id: 1,
        branchId: 1,
        name: 'c',
        usertype: 'counter',
        mobilePassword: '',
        permissions: const ['take_away'],
      ));

      expect(access.canTakeAway, isTrue);
      expect(access.canCashPay, isTrue);
      expect(access.canCardPay, isTrue);
      expect(access.canCreditPay, isTrue);
      expect(access.canPayment, isFalse);
      expect(access.canRecentSales, isFalse);
    });

    test('take-away counter gets payment popup customer and discount sections', () {
      final access = CounterAccess.fromUser(UserModel(
        id: 1,
        branchId: 1,
        name: 'c',
        usertype: 'counter',
        mobilePassword: '',
        permissions: const ['take_away'],
      ));

      expect(access.showCustomerSection, isTrue);
      expect(access.showDiscountSection, isTrue);
      expect(access.canViewCart, isTrue);
      expect(access.canKotPrint, isFalse);
      expect(access.canInvoicePrint, isFalse);
      expect(access.canPrintReceiptOnPayment, isTrue);
    });

    test('payment permission can print invoice at pay without invoice_pr', () {
      final access = CounterAccess.fromUser(UserModel(
        id: 1,
        branchId: 1,
        name: 'c',
        usertype: 'counter',
        mobilePassword: '',
        permissions: const ['payment_p'],
      ));

      expect(access.canPayment, isTrue);
      expect(access.canInvoicePrint, isFalse);
      expect(access.canPrintReceiptOnPayment, isTrue);
    });
  });
}
