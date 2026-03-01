import 'package:flutter/material.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/constants/styles.dart';
import '../../core/constants/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// Current screen: 'dashboard' | 'take_away' | 'take_away_log'. Used to show nav icons to the other screens.
  final String? screen;

  const CustomAppBar({super.key, required this.title, this.screen});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isDashboard = screen == 'dashboard';
    final isTakeAway = screen == 'take_away';
    final isTakeAwayLog = screen == 'take_away_log';

    return AppBar(
      backgroundColor: Colors.white,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.primaryColor),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      title: Text(
        title,
        style: AppStyles.getSemiBoldTextStyle(fontSize: 18),
      ),
      actions: [
        // if (!isDashboard)
        //   IconButton(
        //     icon: const Icon(Icons.home_outlined, color: AppColors.primaryColor),
        //     onPressed: () => AppNavigator.pushReplacementNamed(Routes.dashboard),
        //     tooltip: 'Dashboard',
        //   ),
        // if (!isTakeAway)
        //   IconButton(
        //     icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primaryColor),
        //     onPressed: () => AppNavigator.pushReplacementNamed(Routes.counter),
        //     tooltip: 'Take Away',
        //   ),
        // if (!isTakeAwayLog)
        //   IconButton(
        //     icon: const Icon(Icons.receipt_long_outlined, color: AppColors.primaryColor),
        //     onPressed: () => AppNavigator.pushReplacementNamed(Routes.takeAwayLog),
        //     tooltip: 'Take Away Log',
        //   ),
      ],
    );
  }
}
