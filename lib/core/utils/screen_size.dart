import 'package:flutter/material.dart';

/// Screen size configuration class
class ScreenSize {
  final BuildContext context;

  ScreenSize(this.context);

  /// Get screen width
  double get width => MediaQuery.of(context).size.width;

  /// Get screen height
  double get height => MediaQuery.of(context).size.height;

  /// Get screen aspect ratio
  double get aspectRatio => width / height;

  /// Check if screen is small (phones)
  bool get isSmall => width < 600;

  /// Get responsive width percentage
  double widthPercent(double percent) => width * (percent / 100);

  /// Get responsive height percentage
  double heightPercent(double percent) => height * (percent / 100);

  /// Get safe area padding
  EdgeInsets get safeArea => MediaQuery.of(context).padding;

  /// Get text scale factor
  double get textScaleFactor => MediaQuery.of(context).textScaleFactor;

  /// Get device pixel ratio
  double get devicePixelRatio => MediaQuery.of(context).devicePixelRatio;
}

