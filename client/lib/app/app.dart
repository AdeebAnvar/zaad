import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/update/updater_manager.dart';
import 'package:pos/core/utils/android_storage_permission_prompt.dart';
import 'routes.dart';

class ZaadPOSApp extends StatelessWidget {
  const ZaadPOSApp({
    super.key,
    required this.userType,
    this.initialRouteOverride,
  });

  final UserType? userType;

  /// When non-null, used instead of login for logged-out users (e.g. pending route from DI).
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
        // Update check is scheduled from [PostLoginDeferredStartup] after login is responsive.
        var subtree = child ?? const SizedBox.shrink();
        if (locator.isRegistered<UpdaterManager>()) {
          subtree = locator<UpdaterManager>().wrapAppWithUpdateLayers(subtree);
        }
        // Dismiss IME on scroll (browse lists/items with keyboard open).
        subtree = NotificationListener<UserScrollNotification>(
          onNotification: (_) {
            FocusManager.instance.primaryFocus?.unfocus();
            return false;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            // Earlier bug: unfocus ran only when `!hasPrimaryFocus`, so tap-outside did nothing while typing.
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: subtree,
          ),
        );
        // Desktop / hardware keyboard.
        subtree = Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.escape): _DismissKeyboardIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _DismissKeyboardIntent: CallbackAction<_DismissKeyboardIntent>(
                onInvoke: (_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  return null;
                },
              ),
            },
            child: subtree,
          ),
        );
        return AndroidStoragePermissionPrompt(child: subtree);
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

class _DismissKeyboardIntent extends Intent {
  const _DismissKeyboardIntent();
}
