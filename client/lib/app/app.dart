import 'package:flutter/material.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/presentation/widgets/hub_connection_banner.dart';
import 'routes.dart';

class ZaadPOSApp extends StatelessWidget {
  const ZaadPOSApp({
    super.key,
    required this.userType,
    this.initialRouteOverride,
  });

  final UserType? userType;

  /// When non-null (e.g. first-run setup or unreachable LAN hub), used instead of login for logged-out users.
  final String? initialRouteOverride;
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
        final body = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            final focus = FocusManager.instance.primaryFocus;
            if (focus != null && !focus.hasPrimaryFocus) {
              focus.unfocus();
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HubConnectionBanner(),
            Expanded(child: body),
          ],
        );
      },
      theme: ThemeData(
        fontFamily: 'Poppins',
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
    if (initialRouteOverride != null && initialRouteOverride!.isNotEmpty) {
      return initialRouteOverride!;
    }

    return Routes.login;
  }
}
