import 'package:pos/core/constants/enums.dart';
import 'package:pos/domain/models/user_model.dart';

/// Normalizes permission strings from the server / admin UI for comparison.
///
/// Checked items appear in [UserModel.permissions]; unchecked keys are omitted.
/// Matching is **case-insensitive** and ignores extra spaces / underscores vs spaces.
class CounterPermissions {
  CounterPermissions._();

  static String normalize(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll('_', ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }
}

/// Feature checks for POS users backed by admin permission labels.
///
/// Admin users bypass all checks via [CounterAccess.admin].
///
/// ### Backend `permissions` keys (only enabled keys are sent)
///
/// **Counter / logs:** `couter` (typo), `take_away`, `take_away_log`, `take_away_log_*`,
/// `delivery_sale`, `delivery_log`, `delivery_log_*`, `dine_in`, `dine_in_ta`, `dine_in_log`,
/// `dine_in_log_*`, `dine_in_pay`, `recent_sales`, `recent_sale_delete`, `recent_sale_edit`, …
///
/// **Sale / payment popup:** `cash_only`, `detailing`, `credit_pay`, `kot_print`,
/// `invoice_print`, `discount_item`, `discount_invoice`, `name`, `number`, `email`, `gender`,
/// `address`, `customer_*`, `payment_p`, `printer_settings`, …
///
/// **Drawer / finance:** `expense`, `credit_sale`, `opening_balance`, `crm`, `pay_back`,
/// `open_drawer`, `settle_sale`, `day_closing`, …
class CounterAccess {
  const CounterAccess._({required this.isAdmin, required Set<String> grantedNormalized}) : _granted = grantedNormalized;

  /// Full access (desktop admin role).
  const CounterAccess.admin() : this._(isAdmin: true, grantedNormalized: const {});

  factory CounterAccess.fromUser(UserModel? user) {
    if (user == null) {
      return const CounterAccess._(isAdmin: false, grantedNormalized: {});
    }
    if (user.type == UserType.admin) {
      return const CounterAccess.admin();
    }
    final g = user.permissions.map(CounterPermissions.normalize).where((e) => e.isNotEmpty).toSet();

    final withAliases = {...g};

    /// Backend typo `couter` — treat as counter / counter-sale gates used by [CounterHome].
    if (withAliases.contains('couter')) {
      withAliases.add('counter');
      withAliases.add('counter sale');
      withAliases.add('counter_sale');
    }

    /// Truncated admin keys → dine-in module.
    if (withAliases.contains('dine in ta') ||
        withAliases.contains('dine in table') ||
        withAliases.contains('dine in takeaway')) {
      withAliases.add('dine in');
      withAliases.add('dine_in');
    }

    /// `customer_*` / `customer` → CRM-style customer picker on payment popup.
    if (withAliases.contains('customer') ||
        withAliases.any((k) => k.startsWith('customer '))) {
      withAliases.add('customer save');
      withAliases.add('customer_save');
    }

    return CounterAccess._(isAdmin: false, grantedNormalized: withAliases);
  }

  final bool isAdmin;
  final Set<String> _granted;

  bool _hasAny(Iterable<String> labels) {
    if (isAdmin) return true;
    for (final raw in labels) {
      final n = CounterPermissions.normalize(raw);
      if (n.isEmpty) continue;
      if (_granted.contains(n)) return true;
    }
    return false;
  }

  /// --- Dashboard (counter home) ---
  bool get canTakeAway => _hasAny(const ['take away', 'take_away']);
  bool get canCounterSale => _hasAny(const ['counter sale', 'counter_sale']);

  /// Either explicit take-away permission or legacy "counter sale" also opens take-away counter.
  bool get canTakeAwayCounter => canTakeAway || canCounterSale;

  bool get canTakeAwayLog => _hasAny(const ['take away log', 'take_away_log', 'take away lo', 'take_away_lo']);
  bool get canTakeAwayLogDelete => _hasAny(const ['take away log delete', 'take_away_log_delete']);
  bool get canTakeAwayLogMove => _hasAny(const ['take away log move', 'take_away_log_move']);
  bool get canTakeAwayLogEdit => _hasAny(const ['take away log edit', 'take_away_log_edit']);
  bool get canTakeAwayPay => _hasAny(const ['take away pay', 'take_away_pay']);

  bool get canDeliverySale => _hasAny(const ['delivery sale', 'delivery_sale']);
  bool get canDeliveryLog => _hasAny(const ['delivery log', 'delivery_log', 'delivery lo', 'delivery_lo']);
  bool get canDeliveryLogMove => _hasAny(const ['delivery log move', 'delivery_log_move']);
  bool get canDeliveryLogDelete => _hasAny(const ['delivery log delete', 'delivery_log_delete']);
  bool get canDeliveryLogEdit => _hasAny(const ['delivery log edit', 'delivery_log_edit']);

  bool get canDineIn => _hasAny(const ['dine in', 'dine_in', 'dine in ta', 'dine_in_ta', 'dine in table', 'dine_in_table']);
  bool get canDineInPay => _hasAny(const ['dine in pay', 'dine_in_pay', 'dine in pa', 'dine_in_pa']);
  bool get canDineInLog => _hasAny(const ['dine in log', 'dine_in_log', 'dine in lo', 'dine_in_lo', 'dine in log lo']);
  bool get canDineInLogMove => _hasAny(const ['dine in log move', 'dine_in_log_move']);
  bool get canDineInLogDelete => _hasAny(const ['dine in log delete', 'dine_in_log_delete']);
  bool get canDineInLogEdit => _hasAny(const ['dine in log edit', 'dine_in_log_edit']);
  bool get canDineInLogSplit => _hasAny(const ['dine in log split', 'dine_in_log_split']);

  /// --- Drawer ---
  bool get canOpeningBalance => _hasAny(const ['opening balance', 'opening_balance']);
  bool get canCrm => _hasAny(const ['crm']);
  bool get canRecentSales => _hasAny(const ['recent sales', 'recent_sales', 'recent sal', 'recent_sal']);
  bool get canRecentSaleDelete => _hasAny(const ['recent sale delete', 'recent_sale_delete']);
  bool get canRecentSaleEdit => _hasAny(const ['recent sale edit', 'recent_sale_edit']);
  bool get canCreditSale => _hasAny(const ['credit sale', 'credit_sale', 'credit pay', 'credit_pay']);
  bool get canExpense => _hasAny(const ['expense']);
  bool get canSettleSale => _hasAny(const ['settle sale', 'settle_sale']);
  bool get canPayBack => _hasAny(const ['pay back', 'pay_back']);
  bool get canOpenDrawer => _hasAny(const ['open drawer', 'open_drawer']);

  /// Printer Settings + ESC/POS cash drawer pulse share this gate.
  bool get canPrinterSettings => _hasAny(const ['printer_settings', 'printer settings', 'printer set', 'printer_set']);

  /// Day Closing screen (admin label on server likely "Settle sale" or synonym).
  bool get canDayClosing => _hasAny(const ['day closing', 'day_closing', 'settle sale', 'settle_sale']);

  /// --- Sale screen / payment popup ---
  bool get canPayment => _hasAny(const ['payment', 'payment p', 'payment_p', 'payment pay', 'payment_pay']);

  bool get canCashOnly => _hasAny(const ['cash only', 'cash_only']);

  /// View cart / line-item detail (cart preview).
  bool get canDetailing => _hasAny(const ['detailing', 'detail', 'detailing view']);

  bool get canKotPrint => _hasAny(const ['kot print', 'kot_print']);

  bool get canInvoicePrint => _hasAny(const ['invoice print', 'invoice_print', 'invoice pr', 'invoice_pr']);

  bool get canDiscountItem => _hasAny(const ['discount item', 'discount_item', 'discount i', 'discount_i']);

  bool get canDiscountInvoice => _hasAny(const ['discount invoice', 'discount_invoice']);

  bool get canCustomerName => _hasAny(const ['name', 'customer name', 'customer_name']);

  bool get canCustomerNumber => _hasAny(const ['number', 'customer number', 'customer_number', 'phone', 'mobile']);

  bool get canCustomerEmail => _hasAny(const ['email', 'customer email', 'customer_email']);

  bool get canCustomerGender => _hasAny(const ['gender', 'customer gender', 'customer_gender']);

  bool get canCustomerAddress => _hasAny(const ['address', 'customer address', 'customer_address']);

  /// Customer search / save on payment popup (`customer_*` from admin).
  bool get canCustomer => _hasAny(const [
    'customer',
    'customer save',
    'customer_save',
    'customer crm',
    'customer_crm',
  ]);

  bool get canCreditPay => _hasAny(const ['credit pay', 'credit_pay', 'credit payment', 'credit_payment']);

  bool get canCardPay => !canCashOnly && _hasAny(const ['card pay', 'card_pay', 'card', 'payment']);

  bool get canOnlinePay => !canCashOnly && _hasAny(const ['online pay', 'online_pay', 'online', 'payment']);

  bool get canCashPay => canCashOnly || _hasAny(const ['cash pay', 'cash_pay', 'cash', 'payment']);

  /// Payment popup / move-order customer block — only the four profile fields (+ address when used).
  bool get showCustomerSection =>
      canCustomerName || canCustomerNumber || canCustomerEmail || canCustomerGender || canCustomerAddress;

  bool get showDiscountSection => canDiscountItem || canDiscountInvoice;
}

/// Last resolved login user profile (for contexts without BuildContext — e.g. [CartCubit]).
///
/// Cleared on logout.
class CurrentCounterSession {
  UserModel? user;

  CounterAccess get access => CounterAccess.fromUser(user);

  void setUser(UserModel? u) {
    user = u;
  }

  void clear() {
    user = null;
  }
}
