import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/sync/sync_service.dart';
import 'package:pos/data/local/drift_database.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/styles.dart';
import '../../app/navigation.dart';

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
      icon: Icons.shopping_cart_outlined,
      title: "Take Away",
      route: "/counter",
    ),
    DrawerMenuItem(
      icon: Icons.receipt_long_outlined,
      title: "Take Away Log",
      route: "/take_away_log",
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
    return SlideTransition(
      position: _slideAnimation,
      child: Drawer(
        width: widget.width,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            _header(),
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
                    onTap: () => _navigate(item.route),
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
    final sync = SyncService.instance;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      color: AppColors.primaryColor.withOpacity(0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.companyLogo.isNotEmpty
              ? Image.file(
                  File(widget.companyLogo),
                  errorBuilder: (c, e, s) {
                    return Image.asset(
                      'assets/images/png/appicon2.webp',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    );
                  },
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/images/png/appicon2.webp',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
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
          const SizedBox(height: 12),
          Text(
            sync.lastSyncedAt == null ? "Not synced" : "Last sync: ${_formatSyncTime(sync.lastSyncedAt!)}",
            style: AppStyles.getRegularTextStyle(
              fontSize: 11,
              color: AppColors.hintFontColor,
            ),
          ),
        ],
      ),
    );
  }

  // ================= MENU ITEM =================

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
  void _navigate(String route) {
    AppNavigator.pop(); // close drawer

    if (AppNavigator.currentRoute == route) return;

    AppNavigator.pushReplacementNamed(route);
  }

  void _logout() async {
    await locator<AppDatabase>().sessionDao.clearSession();

    AppNavigator.pop();
    AppNavigator.pushReplacementNamed("/login");
  }

  String _formatSyncTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM dd, hh:mm a').format(dateTime);
    }
  }
}

class DrawerMenuItem {
  final IconData icon;
  final String title;
  final String route;
  final Color? color;

  const DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.route,
    this.color,
  });
}
