import 'package:flutter/material.dart';

/// Simple utility class for mobile only
class ResponsiveUtils {
  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get responsive value - returns mobile value only
  static T responsiveValue<T>(BuildContext context, {required T mobile}) {
    return mobile;
  }

  /// Get responsive font size - returns mobile value only
  static double responsiveFontSize(BuildContext context, {required double mobile}) {
    return mobile;
  }

  /// Get responsive spacing - returns mobile value only
  static double responsiveSpacing(BuildContext context, {required double mobile}) {
    return mobile;
  }

  /// Get responsive icon size - returns mobile value only
  static double responsiveIconSize(BuildContext context, {required double mobile}) {
    return mobile;
  }

  /// Check if screen is mobile size (always true for mobile-only app)
  static bool isMobile(BuildContext context) {
    return true;
  }

  /// Get responsive grid columns - returns mobile value only (2 columns)
  static int responsiveGridColumns(BuildContext context) {
    return 2;
  }

  /// Get responsive card padding - returns mobile value only
  static EdgeInsets responsiveCardPadding(BuildContext context) {
    return const EdgeInsets.all(16.0);
  }

  /// Get responsive padding - returns mobile value only
  static EdgeInsets responsivePadding(BuildContext context) {
    return const EdgeInsets.all(16.0);
  }

  /// Get max content width - returns mobile value only
  static double maxContentWidth(BuildContext context) {
    return double.infinity;
  }
}

