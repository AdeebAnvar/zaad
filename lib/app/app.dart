import 'package:flutter/material.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/enums.dart';
import 'routes.dart';

class ZaadPOSApp extends StatelessWidget {
  const ZaadPOSApp({super.key, required this.userType});
  final UserType? userType;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Zaad POS",
      navigatorObservers: [
        AppRouteObserver(),
      ],
      navigatorKey: AppNavigator.navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: _resolveHome(),
      routes: Routes.map,
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            final focus = FocusManager.instance.primaryFocus;
            if (focus != null && !focus.hasPrimaryFocus) {
              focus.unfocus();
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.scaffoldColor,
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: AppColors.textColor),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: AppColors.hintFontColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _resolveHome() {
    if (userType != null) {
      return Routes.dashboard;
    }

    return Routes.login;
  }
}
