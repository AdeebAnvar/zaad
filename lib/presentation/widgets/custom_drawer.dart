import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/data/local/drift_database.dart';
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
  const PosDrawer({
    super.key,
    required this.userName,
    required this.role,
    required this.companyName,
    required this.companyLogo,
    required this.width,
  });

  @override
  State<PosDrawer> createState() => _PosDrawerState();
}

class _PosDrawerState extends State<PosDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  final List<DrawerMenuItem> _menus = [
    DrawerMenuItem(
      icon: Icons.dashboard,
      title: "Dashboard",
      route: "/dashboard",
    ),
    DrawerMenuItem(
      icon: Icons.person_outlined,
      title: "CRM",
      route: "/crm",
    ),
    DrawerMenuItem(
      icon: Icons.edit_document,
      title: "Recent Sales",
      route: "/recent_sales",
    ),
    DrawerMenuItem(
      icon: Icons.account_balance_wallet_outlined,
      title: "Credit Sales",
      route: Routes.creditSales,
    ),
    DrawerMenuItem(
      icon: Icons.print_outlined,
      title: "Printer Settings",
      route: Routes.printerSettings,
    ),
    DrawerMenuItem(
      icon: Icons.event_available_rounded,
      title: "Day Closing",
      route: Routes.dayClosing,
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
    return SlideTransition(
      position: _slideAnimation,
      child: Drawer(
        width: drawerWidth,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            _header(),
            _openingBalanceTile(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _menus.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = _menus[index];
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
    final logoWidget = widget.companyLogo.isNotEmpty
        ? Image.file(
            File(widget.companyLogo),
            errorBuilder: (c, e, s) {
              return Image.asset(
                'assets/images/png/appicon2.webp',
                width: 96,
                height: 96,
                fit: BoxFit.contain,
              );
            },
            // width: 96,
            // height: 96,
            fit: BoxFit.contain,
          )
        : Image.asset(
            'assets/images/png/appicon2.webp',
            width: 96,
            height: 96,
            fit: BoxFit.cover,
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      color: AppColors.primaryColor.withOpacity(0.06),
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 108,
            height: 108,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: logoWidget),
          ),
          const SizedBox(height: 12),
          Text(
            widget.companyName.isNotEmpty ? widget.companyName : "Company Name",
            style: AppStyles.getBoldTextStyle(fontSize: 16, color: Colors.black),
          ),
          const Divider(height: 24),
          Text(
            widget.userName.isNotEmpty ? widget.userName : "User",
            style: AppStyles.getMediumTextStyle(fontSize: 14),
          ),
          Text(
            widget.role.isNotEmpty ? widget.role.substring(0, 1).toUpperCase() + widget.role.substring(1) : "",
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
    final controller = TextEditingController(text: current.toString());

    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Opening Balance',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
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
                      controller: controller,
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
                              final parsed = int.tryParse(controller.text.trim());
                              if (parsed == null || parsed < 0) {
                                CustomSnackBar.showWarning(message: 'Enter a valid opening balance');
                                return;
                              }
                              await db.branchesDao.updateOpeningCash(
                                branchId: session.branchId,
                                openingCashValue: parsed,
                              );
                              FocusScope.of(context).unfocus();
                              if (context.mounted) Navigator.pop(context);
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
    controller.dispose();
  }

  void _logout() async {
    await locator<AppDatabase>().sessionDao.clearSession();

    AppNavigator.pop();
    AppNavigator.pushReplacementNamed("/login");
  }
}

class DrawerMenuItem {
  final IconData icon;
  final String title;
  final String route;
  final Color? color;

  /// Optional [Navigator] arguments (e.g. delivery counter: orderType + partner).
  final Map<String, dynamic>? arguments;

  const DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.route,
    this.color,
    this.arguments,
  });
}
