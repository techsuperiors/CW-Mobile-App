import 'package:flutter/widgets.dart';

/// Centralized spacing system (8pt grid based)
class AppSpacing {
  // Base spacing scale
  static const double xxs = 2.0;   // extra small
  static const double xs = 4.0;   // extra small
  static const double sm = 8.0;   // small
  static const double md = 12.0;  // medium
  static const double lg = 16.0;  // large (most used)
  static const double xl = 24.0;  // extra large
  static const double xxl = 32.0; // very large

  //Icon Height and width
  static const double iconMediumHeight = 42.0;
  static const double iconMediumWidth = 42.0;

  static const double iconSmallHeight = 24.0;
  static const double iconSmallWidth = 24.0;


  // Section spacing (for bigger layouts)
  static const double section = 40.0;
  static const double sectionLarge = 56.0;

  // Common paddings
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets screenPaddingLarge = EdgeInsets.symmetric(horizontal: 24.0);

  static const EdgeInsets pagePadding = EdgeInsets.all(16.0);

  // Card spacing
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(12.0);

  // Input / field spacing
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0);

  // Button spacing
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

  // List spacing
  static const EdgeInsets listItemSpacing = EdgeInsets.symmetric(vertical: 8.0);

  // Utility sized boxes (shortcut)
  static const SizedBox vXxs = SizedBox(height: xxs);
  static const SizedBox vXs = SizedBox(height: xs);
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox vXl = SizedBox(height: xl);

  static const SizedBox hXss = SizedBox(width: xxs);
  static const SizedBox hXs = SizedBox(width: xs);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
  static const SizedBox hLg = SizedBox(width: lg);
  static const SizedBox hXl = SizedBox(width: xl);
}