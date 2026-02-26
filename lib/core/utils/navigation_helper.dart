import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/request/presentation/pages/request_bottom_sheet.dart';

/// Helper class for navigation with bottom nav bar support
class NavigationHelper {
  /// Navigate to HomePage and switch to a specific tab
  /// This should be used by all bottom nav bars across the app
  static void navigateToHomeTab(BuildContext context, int tabIndex) {
    final navigator = Navigator.of(context);
    
    // Check if we're already on HomePage
    final currentRoute = ModalRoute.of(context);
    if (currentRoute?.settings.name == '/home') {
      // We're on HomePage, just update the tab
      // This will be handled by HomePage's state management
      return;
    }

    // Pop all routes and navigate to HomePage with specific tab
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomePage(initialTabIndex: tabIndex),
        settings: const RouteSettings(name: '/home'),
      ),
      (route) => false,
    );
  }

  /// Get bottom nav bar handler for any page
  /// Use this in pages that need bottom navigation
  /// Handles request bottom sheet when index 3 (Request) is tapped
  static Function(int) getBottomNavHandler(BuildContext context) {
    return (int index) {
      // Show bottom sheet for Request button (index 3)
      if (index == 3) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const RequestBottomSheet(),
        );
      } else {
        navigateToHomeTab(context, index);
      }
    };
  }
}
