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

    return AppBar(
      backgroundColor: Colors.white,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      centerTitle: true,
      leadingWidth: 95,
      leading: Row(
        children: [
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.menu, color: Colors.white),
            ),
          ),
          if (!isDashboard)
            GestureDetector(
              onTap: () => AppNavigator.pushReplacementNamed(Routes.dashboard),
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.home_filled, color: Colors.white),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: AppStyles.getSemiBoldTextStyle(fontSize: 18),
      ),
      actions: [],
    );
  }
}
