import 'package:flutter/material.dart';
import '../../features/approval/presentation/pages/approval_bottom_sheet.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/request/presentation/pages/request_bottom_sheet.dart';
import '../../features/home/presentation/cubit/home_page_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Helper class for navigation with bottom nav bar support
class NavigationHelper {
  /// Navigates to the [HomePage] and switches to the specified tab
  /// without recreating the [HomePage] instance.
  ///
  /// This method should be used across the entire app whenever
  /// bottom navigation tab switching is required.
  ///
  /// Unlike [Navigator.pushAndRemoveUntil], this approach:
  /// - Preserves the existing [HomePage] state (no reload)
  /// - Keeps [IndexedStack] pages alive in memory
  /// - Prevents unnecessary API calls on navigation
  ///
  /// [context] - Must have access to [HomePageCubit] in the widget tree
  /// [tabIndex] - The index of the tab to switch to (0-4)
  static void navigateToHomeTab(BuildContext context, int tabIndex) {
    // Pop all pushed routes (e.g. ApplyLeave, Listings, Details)
    // until we reach the root route where HomePage lives.
    // This does NOT destroy HomePage — it just clears the route stack above it.
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Emit the new tab index via HomePageCubit.
    // HomePage's IndexedStack listens to this and switches
    // the visible page without rebuilding or reloading any data.
    context.read<HomePageCubit>().switchTab(tabIndex);
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
        if (index == 4) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const ApprovalBottomSheet(),
          );
        } else {
          navigateToHomeTab(context, index);
        }
      }
    };
  }
}
