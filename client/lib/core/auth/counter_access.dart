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
/// Typical tenant responses include (underscore / casing may vary): `couter` (server typo for counter),
/// `expense`, `credit_sale`, `Recent_sales` / `recent_sales`, `recent_sale_delete`, `recent_sale_edit`,
/// `settle_sale`, `opening_balance`, `crm`, `pay_back`, `open_drawer`,
/// `delivery_log`, `delivery_log_move`, `delivery_log_delete`, `delivery_log_edit`,
/// `take_away_log`, `take_away_log_delete`, `take_away_log_move`, `take_away_log_edit`,
/// `delivery_sale`, `take_away`, `take_away_pay`, `dine_in`, `dine_in_pay`,
/// `dine_in_log`, `dine_in_log_move`, `dine_in_log_delete`, `dine_in_log_edit`, `dine_in_log_split`.
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

    /// Backend typo `couter` — treat as counter / counter-sale gates used by [CounterHome].
    final withAliases = {...g};
    if (withAliases.contains('couter')) {
      withAliases.add('counter');
      withAliases.add('counter sale');
      withAliases.add('counter_sale');
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

  bool get canTakeAwayLog => _hasAny(const ['take away log', 'take_away_log']);
  bool get canTakeAwayLogDelete => _hasAny(const ['take away log delete', 'take_away_log_delete']);
  bool get canTakeAwayLogMove => _hasAny(const ['take away log move', 'take_away_log_move']);
  bool get canTakeAwayLogEdit => _hasAny(const ['take away log edit', 'take_away_log_edit']);
  bool get canTakeAwayPay => _hasAny(const ['take away pay', 'take_away_pay']);

  bool get canDeliverySale => _hasAny(const ['delivery sale', 'delivery_sale']);
  bool get canDeliveryLog => _hasAny(const ['delivery log', 'delivery_log']);
  bool get canDeliveryLogMove => _hasAny(const ['delivery log move', 'delivery_log_move']);
  bool get canDeliveryLogDelete => _hasAny(const ['delivery log delete', 'delivery_log_delete']);
  bool get canDeliveryLogEdit => _hasAny(const ['delivery log edit', 'delivery_log_edit']);

  bool get canDineIn => _hasAny(const ['dine in', 'dine_in']);
  bool get canDineInPay => _hasAny(const ['dine in pay', 'dine_in_pay']);
  bool get canDineInLog => _hasAny(const ['dine in log', 'dine_in_log']);
  bool get canDineInLogMove => _hasAny(const ['dine in log move', 'dine_in_log_move']);
  bool get canDineInLogDelete => _hasAny(const ['dine in log delete', 'dine_in_log_delete']);
  bool get canDineInLogEdit => _hasAny(const ['dine in log edit', 'dine_in_log_edit']);
  bool get canDineInLogSplit => _hasAny(const ['dine in log split', 'dine_in_log_split']);

  /// --- Drawer ---
  bool get canOpeningBalance => _hasAny(const ['opening balance', 'opening_balance']);
  bool get canCrm => _hasAny(const ['crm']);
  bool get canRecentSales => _hasAny(const ['recent sales', 'recent_sales']);
  bool get canRecentSaleDelete => _hasAny(const ['recent sale delete', 'recent_sale_delete']);
  bool get canRecentSaleEdit => _hasAny(const ['recent sale edit', 'recent_sale_edit']);
  bool get canCreditSale => _hasAny(const ['credit sale', 'credit_sale']);
  bool get canExpense => _hasAny(const ['expense']);
  bool get canSettleSale => _hasAny(const ['settle sale', 'settle_sale']);
  bool get canPayBack => _hasAny(const ['pay back', 'pay_back']);
  bool get canOpenDrawer => _hasAny(const ['open drawer', 'open_drawer']);

  /// Printer Settings + ESC/POS cash drawer pulse share this gate.
  bool get canPrinterSettings => _hasAny(const ["printer_settings", 'printer settings']);

  /// Day Closing screen (admin label on server likely "Settle sale" or synonym).
  bool get canDayClosing => _hasAny(const ['day closing', 'day_closing', 'settle sale', 'settle_sale']);
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
