import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/settings_repository.dart';
import 'package:pos/domain/models/user_model.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/styles.dart';
import '../../app/navigation.dart';
import '../../app/routes.dart';

class PosDrawer extends StatefulWidget {
  final String userName;
  final String role;
  final String companyName;
  final String companyLogo;
  final double width;
  /// Logged-in user profile (permissions). When null, menu uses empty counter grants except Dashboard.
  final UserModel? sessionUser;

  const PosDrawer({
    super.key,
    required this.userName,
    required this.role,
    required this.companyName,
    required this.companyLogo,
    required this.width,
    this.sessionUser,
  });

  @override
  State<PosDrawer> createState() => _PosDrawerState();
}

class _PosDrawerState extends State<PosDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  List<DrawerMenuItem> _allMenuItems() => [
        DrawerMenuItem(
          icon: Icons.dashboard,
          title: 'Dashboard',
          route: '/dashboard',
          visibleWhen: (_) => true,
        ),
        DrawerMenuItem(
          icon: Icons.person_outlined,
          title: 'CRM',
          route: '/crm',
          visibleWhen: (a) => a.canCrm,
        ),
        DrawerMenuItem(
          icon: Icons.edit_document,
          title: 'Recent Sales',
          route: '/recent_sales',
          visibleWhen: (a) => a.canRecentSales,
        ),
        DrawerMenuItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Credit Sales',
          route: Routes.creditSales,
          visibleWhen: (a) => a.canCreditSale,
        ),
        DrawerMenuItem(
          icon: Icons.print_outlined,
          title: 'Printer Settings',
          route: Routes.printerSettings,
          visibleWhen: (a) => a.canPrinterSettings,
        ),
        DrawerMenuItem(
          icon: Icons.settings_ethernet,
          title: 'LAN hub',
          route: Routes.lanHubSettings,
          visibleWhen: (_) => true,
        ),
        DrawerMenuItem(
          icon: Icons.event_available_rounded,
          title: 'Day Closing',
          route: Routes.dayClosing,
          visibleWhen: (a) => a.canDayClosing,
        ),
      ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dynamicWidth = screenWidth < 700 ? (screenWidth * 0.78).clamp(260.0, 340.0) : (screenWidth * 0.30).clamp(300.0, 420.0);
    final drawerWidth = widget.width > 0
        ? dynamicWidth > widget.width
            ? dynamicWidth
            : widget.width
        : dynamicWidth;

    final access = CounterAccess.fromUser(widget.sessionUser);
    final menus = _allMenuItems().where((m) => m.visibleWhen(access)).toList();

    return SlideTransition(
      position: _slideAnimation,
      child: Drawer(
        width: drawerWidth,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            _header(),
            if (access.canOpeningBalance) _openingBalanceTile(),
            if (access.canOpenDrawer) _openCashDrawerTile(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: menus.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = menus[index];
                  return _menuItem(
                    icon: item.icon,
                    title: item.title,
                    onTap: () => _navigate(item.route, arguments: item.arguments),
                    color: item.color ?? AppColors.textColor,
                  );
                },
              ),
            ),
            const Divider(),
            _menuItem(
              icon: Icons.logout,
              title: "Logout",
              color: Colors.red,
              onTap: _logout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    Widget logoImage() {
      const size = 96.0;
      if (widget.companyLogo.isNotEmpty) {
        return Image.file(
          File(widget.companyLogo),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) {
            return Image.asset(
              'assets/images/png/appicon2.webp',
              width: size,
              height: size,
              fit: BoxFit.cover,
            );
          },
        );
      }
      return Image.asset(
        'assets/images/png/appicon2.webp',
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      color: AppColors.primaryColor.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Center(child: logoImage()),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.companyName.isNotEmpty ? widget.companyName : "Company Name",
            textAlign: TextAlign.center,
            style: AppStyles.getBoldTextStyle(fontSize: 16, color: Colors.black),
          ),
          Divider(height: 24, color: Colors.grey.shade300),
          Text(
            widget.userName.isNotEmpty ? widget.userName : "User",
            textAlign: TextAlign.center,
            style: AppStyles.getMediumTextStyle(fontSize: 14),
          ),
          Text(
            widget.role.isNotEmpty
                ? (widget.role.length == 1
                    ? widget.role.toUpperCase()
                    : widget.role.substring(0, 1).toUpperCase() + widget.role.substring(1))
                : "",
            textAlign: TextAlign.center,
            style: AppStyles.getRegularTextStyle(
              fontSize: 12,
              color: AppColors.hintFontColor,
            ),
          ),
        ],
      ),
    );
  }

  // ================= MENU ITEM =================

  Widget _openingBalanceTile() {
    return ListTile(
      leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textColor),
      title: Text(
        "Opening Balance",
        style: AppStyles.getMediumTextStyle(
          fontSize: 14,
          color: AppColors.textColor,
        ),
      ),
      onTap: _showOpeningBalanceDialog,
    );
  }

  Widget _openCashDrawerTile() {
    return ListTile(
      leading: const Icon(Icons.point_of_sale_outlined, color: AppColors.textColor),
      title: Text(
        'Open cash drawer',
        style: AppStyles.getMediumTextStyle(
          fontSize: 14,
          color: AppColors.textColor,
        ),
      ),
      onTap: _showCashDrawerPasswordDialog,
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = AppColors.textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: AppStyles.getMediumTextStyle(
          fontSize: 14,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }

  // ================= ACTIONS =================
  void _navigate(String route, {Map<String, dynamic>? arguments}) {
    // Safety guard for legacy menu entries during hot-reload sessions.
    if (route == "__opening_balance__") {
      _showOpeningBalanceDialog();
      return;
    }
    AppNavigator.pop(); // close drawer

    // Same route without args (e.g. dashboard): avoid redundant replace.
    if (arguments == null && AppNavigator.currentRoute == route) return;

    AppNavigator.pushReplacementNamed(route, args: arguments);
  }

  Future<void> _showOpeningBalanceDialog() async {
    final db = locator<AppDatabase>();
    final session = await db.sessionDao.getActiveSession();
    if (session == null || !mounted) return;

    final branch = await db.branchesDao.getBranchById(session.branchId);
    final current = branch?.openingCash ?? 0;

    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Opening Balance',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        return _OpeningBalanceDialogContent(
          initialAmountText: current.toString(),
          db: db,
          branchId: session.branchId,
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showCashDrawerPasswordDialog() async {
    final settings = await locator<SettingsRepository>().getSettingsFromLocal();
    final expected = settings?.drawerPassword.trim() ?? '';
    if (expected.isEmpty) {
      if (!mounted) return;
      CustomSnackBar.showWarning(
        message: 'Set the drawer password in Settings before opening the cash drawer.',
      );
      return;
    }

    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Open cash drawer',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return _CashDrawerPasswordDialogContent(
          drawerHostContext: context,
          dialogContext: dialogContext,
          expectedPassword: expected,
          onOpenDrawer: ({
            required BuildContext dialogContext,
            required BuildContext drawerHostContext,
            required String entered,
            required String expected,
          }) =>
              _tryOpenCashDrawerAfterPassword(
                dialogContext: dialogContext,
                drawerHostContext: drawerHostContext,
                entered: entered,
                expected: expected,
              ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _tryOpenCashDrawerAfterPassword({
    required BuildContext dialogContext,
    required BuildContext drawerHostContext,
    required String entered,
    required String expected,
  }) async {
    if (entered.isEmpty) {
      CustomSnackBar.showWarning(message: 'Enter the drawer password');
      return;
    }
    if (entered != expected) {
      CustomSnackBar.showWarning(message: 'Incorrect password');
      return;
    }

    FocusScope.of(dialogContext).unfocus();
    if (dialogContext.mounted) Navigator.pop(dialogContext);
    if (drawerHostContext.mounted) Navigator.pop(drawerHostContext);

    await locator<PrintService>().openCashDrawer();
  }

  void _logout() async {
    await locator<AppDatabase>().sessionDao.clearSession();
    locator<CurrentCounterSession>().clear();

    AppNavigator.pop();
    AppNavigator.pushReplacementNamed("/login");
  }
}

typedef _CashDrawerSubmit = Future<void> Function({
  required BuildContext dialogContext,
  required BuildContext drawerHostContext,
  required String entered,
  required String expected,
});

class _OpeningBalanceDialogContent extends StatefulWidget {
  const _OpeningBalanceDialogContent({
    required this.initialAmountText,
    required this.db,
    required this.branchId,
  });

  final String initialAmountText;
  final AppDatabase db;
  final int branchId;

  @override
  State<_OpeningBalanceDialogContent> createState() =>
      _OpeningBalanceDialogContentState();
}

class _OpeningBalanceDialogContentState extends State<_OpeningBalanceDialogContent> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.initialAmountText);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 430,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Opening Balance',
                      style: AppStyles.getBoldTextStyle(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final parsed = int.tryParse(_amountController.text.trim());
                          if (parsed == null || parsed < 0) {
                            CustomSnackBar.showWarning(message: 'Enter a valid opening balance');
                            return;
                          }
                          await widget.db.branchesDao.updateOpeningCash(
                            branchId: widget.branchId,
                            openingCashValue: parsed,
                          );
                          if (!mounted) return;
                          FocusScope.of(context).unfocus();
                          Navigator.pop(context);
                          CustomSnackBar.showSuccess(message: 'Opening balance updated');
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CashDrawerPasswordDialogContent extends StatefulWidget {
  const _CashDrawerPasswordDialogContent({
    required this.drawerHostContext,
    required this.dialogContext,
    required this.expectedPassword,
    required this.onOpenDrawer,
  });

  final BuildContext drawerHostContext;
  final BuildContext dialogContext;
  final String expectedPassword;
  final _CashDrawerSubmit onOpenDrawer;

  @override
  State<_CashDrawerPasswordDialogContent> createState() =>
      _CashDrawerPasswordDialogContentState();
}

class _CashDrawerPasswordDialogContentState extends State<_CashDrawerPasswordDialogContent> {
  late final TextEditingController _passwordController;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await widget.onOpenDrawer(
      dialogContext: widget.dialogContext,
      drawerHostContext: widget.drawerHostContext,
      entered: _passwordController.text.trim(),
      expected: widget.expectedPassword,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => FocusScope.of(widget.dialogContext).unfocus(),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 430,
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(widget.dialogContext).height * 0.85),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.point_of_sale_rounded,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Open cash drawer',
                          style: AppStyles.getBoldTextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the drawer password from Settings.',
                    style: AppStyles.getRegularTextStyle(
                      fontSize: 13,
                      color: AppColors.hintFontColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            FocusScope.of(widget.dialogContext).unfocus();
                            Navigator.pop(widget.dialogContext);
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _submit,
                          child: const Text('Open drawer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DrawerMenuItem {
  final IconData icon;
  final String title;
  final String route;
  final Color? color;

  /// Optional [Navigator] arguments (e.g. delivery counter: orderType + partner).
  final Map<String, dynamic>? arguments;

  final bool Function(CounterAccess access) visibleWhen;

  DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.route,
    this.color,
    this.arguments,
    required this.visibleWhen,
  });
}
