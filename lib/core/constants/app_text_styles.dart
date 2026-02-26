import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Common text styles using MediaQuery for responsive font sizes
class AppTextStyles {
  /// Calculate font size directly from MediaQuery
  static double _calculateFontSize(BuildContext context, double baseSize) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Use MediaQuery to calculate font size based on screen dimensions
    // Use the smaller dimension to prevent text from becoming too large
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    
    // Calculate font size as percentage of the smaller dimension
    // Reference: 360px width for small phones
    final basePercentage = baseSize / 360.0;
    final fontSize = smallerDimension * basePercentage;
    
    // Apply text scale factor from system settings (clamped for readability)
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return fontSize * textScaleFactor;
  }

  /// Get spacing for mobile with MediaQuery scaling
  static double getSpacing(
    BuildContext context, {
    required double mobile,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Scale spacing based on screen height
    // For very small screens (< 600px), reduce spacing
    // For larger screens, maintain or slightly increase
    double scaleFactor = 1.0;
    if (screenHeight < 600) {
      scaleFactor = 0.85;
    } else if (screenHeight < 700) {
      scaleFactor = 0.9;
    }
    
    return mobile * scaleFactor;
  }

  // Headings
  static TextStyle heading1(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (26.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      fontFamily: 'Inter',
    );
  }

  static TextStyle heading2(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (20.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle heading3(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (20.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle heading4(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (18.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle heading5(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (14.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  // Body Text
  static TextStyle bodyLarge(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (18.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (16.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle bodySmall(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (12.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondary,
    );
  }

  // Labels
  static TextStyle labelLarge(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (14.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle labelMedium(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (14.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      fontFamily: 'Roboto',
    );
  }

  static TextStyle labelSmall(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (10.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    );
  }

  // Buttons
  static TextStyle buttonLarge(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (16.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: AppColors.textWhite,
    );
  }

  static TextStyle buttonMedium(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (14.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: AppColors.textWhite,
    );
  }

  static TextStyle buttonSmall(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (12.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: AppColors.textWhite,
    );
  }

  // Caption
  static TextStyle caption(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fontSize = (12.0 / 360.0) * smallerDimension * mediaQuery.textScaleFactor.clamp(0.9, 1.2);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondary,
    );
  }
}
