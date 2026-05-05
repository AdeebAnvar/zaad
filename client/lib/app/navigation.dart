import 'package:flutter/material.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static String? currentRoute;

  static void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  static Future<T?> pushNamed<T>(String route, {Object? args}) {
    if (currentRoute == route) return Future.value(null);
    _dismissKeyboard();
    return navigatorKey.currentState!.pushNamed<T>(route, arguments: args);
  }

  static void pushReplacementNamed(String route, {Object? args}) {
    if (currentRoute == route) return;
    _dismissKeyboard();
    navigatorKey.currentState!.pushReplacementNamed(route, arguments: args);
  }

  static void pop<T>([T? result]) {
    _dismissKeyboard();
    navigatorKey.currentState?.pop(result);
  }
}

class AppRouteObserver extends NavigatorObserver {
  static void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    AppNavigator.currentRoute = route.settings.name;
    _dismissKeyboard();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    AppNavigator.currentRoute = newRoute?.settings.name;
    _dismissKeyboard();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    AppNavigator.currentRoute = previousRoute?.settings.name;
    _dismissKeyboard();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _dismissKeyboard();
  }
}
