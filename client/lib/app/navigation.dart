import 'package:flutter/material.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static String? currentRoute;

  static Future<T?> pushNamed<T>(String route, {Object? args}) {
    if (currentRoute == route) return Future.value(null);
    return navigatorKey.currentState!.pushNamed<T>(route, arguments: args);
  }

  static void pushReplacementNamed(String route, {Object? args}) {
    if (currentRoute == route) return;
    navigatorKey.currentState!.pushReplacementNamed(route, arguments: args);
  }

  static void pop<T>([T? result]) {
    navigatorKey.currentState?.pop(result);
  }
}

class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    AppNavigator.currentRoute = route.settings.name;
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    AppNavigator.currentRoute = newRoute?.settings.name;
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    AppNavigator.currentRoute = previousRoute?.settings.name;
  }
}
