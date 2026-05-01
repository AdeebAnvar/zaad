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
class CounterAccess {
  const CounterAccess._({required this.isAdmin, required Set<String> grantedNormalized})
      : _granted = grantedNormalized;

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

    /// Common alias from admin typo "Couter"
    final withAliases = {...g};
    if (withAliases.contains('couter')) {
      withAliases.add('counter');
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

  bool get canDeliverySale => _hasAny(const ['delivery sale', 'delivery_sale']);
  bool get canDeliveryLog => _hasAny(const ['delivery log', 'delivery_log']);

  bool get canDineIn => _hasAny(const ['dine in', 'dine_in']);
  bool get canDineInLog => _hasAny(const ['dine in log', 'dine_in_log']);

  /// --- Drawer ---
  bool get canOpeningBalance => _hasAny(const ['opening balance', 'opening_balance']);
  bool get canCrm => _hasAny(const ['crm']);
  bool get canRecentSales => _hasAny(const ['recent sales', 'recent_sales']);
  bool get canRecentSaleDelete => _hasAny(const ['recent sale delete', 'recent_sale_delete']);
  bool get canCreditSale => _hasAny(const ['credit sale', 'credit_sale']);
  bool get canExpense => _hasAny(const ['expense']);
  bool get canSettleSale => _hasAny(const ['settle sale', 'settle_sale']);
  bool get canPayBack => _hasAny(const ['pay back', 'pay_back']);
  bool get canOpenDrawer => _hasAny(const ['open drawer', 'open_drawer']);

  /// Printer Settings + ESC/POS cash drawer pulse share this gate.
  bool get canPrinterSettings => canOpenDrawer;

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
