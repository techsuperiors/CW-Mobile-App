import 'package:flutter/material.dart';

/// Global navigator key for app-wide navigation
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigate to a route
  static Future<T?>? push<T>(Route<T> route) {
    return navigatorKey.currentState?.push(route);
  }

  /// Navigate and remove all previous routes
  static void pushAndRemoveUntil<T>(Route<T> newRoute, bool Function(Route) predicate) {
    navigatorKey.currentState?.pushAndRemoveUntil(newRoute, predicate);
  }

  /// Pop current route
  static void pop<T>([T? result]) {
    navigatorKey.currentState?.pop(result);
  }

  /// Clear all routes and navigate to a new route
  static void pushAndRemoveAll(Route newRoute) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      newRoute,
      (route) => false, // Remove all previous routes
    );
  }
}

