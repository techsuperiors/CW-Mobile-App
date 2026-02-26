import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import 'sub_requets/leaves/presentation/pages/apply_leave_page_listing.dart';
import 'sub_requets/wfh/presentation/pages/wfh_page_listing.dart';
import 'sub_requets/regularize/presentation/pages/regularize_page_listing.dart';

/// Request bottom sheet widget
class RequestBottomSheet extends StatelessWidget {
  const RequestBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate dynamic sizes based on screen dimensions
    final horizontalPadding = screenWidth * 0.05; // 5% of screen width
    final verticalPadding = screenHeight * 0.03; // 3% of screen height
    final iconSize = screenWidth * 0.12; // 12% of screen width for icon container
    final buttonSize = (screenWidth - (horizontalPadding * 2) - (screenWidth * 0.06)) / 3; // Dynamic button size
    final spacing = screenWidth * 0.03; // 3% spacing between buttons

    return SizedBox(
      height: screenHeight,
      width: screenWidth,
      child: Stack(
        children: [
          // Full-screen blurred backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
          ),
        // Bottom sheet content
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header Section
          Row(
            children: [
              // Teal pencil icon
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF009688), // Teal color
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.request,
                      style: TextStyle(
                        fontSize: screenWidth * 0.06, // 6% of screen width
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.requestDescription,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035, // 3.5% of screen width
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.03), // 3% of screen height
          
          // Request buttons grid (2x3)
          _buildRequestGrid(
            context: context,
            buttonSize: buttonSize,
            spacing: spacing,
          ),
          
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildRequestGrid({
    required BuildContext context,
    required double buttonSize,
    required double spacing,
  }) {
    return Column(
      children: [
        // First row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRequestButton(
              context: context,
              title: AppStrings.applyLeave,
              icon: Icons.calendar_today_outlined,
              color: const Color(0xFFE91E63), // Hot pink
              size: buttonSize,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApplyLeavePageListing(),
                  ),
                );
              },
            ),
            SizedBox(width: spacing),
            _buildRequestButton(
              context: context,
              title: AppStrings.wfh,
              icon: Icons.home_outlined,
              color: const Color(0xFF1976D2), // Royal blue
              size: buttonSize,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WfhPageListing(),
                  ),
                );
              },
            ),
            SizedBox(width: spacing),
            _buildRequestButton(
              context: context,
              title: AppStrings.regularize,
              icon: Icons.check_circle_outline,
              color: const Color(0xFF9C27B0), // Vibrant purple
              size: buttonSize,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegularizePageListing(),
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: spacing),
        // Second row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRequestButton(
              context: context,
              title: AppStrings.onDuty,
              icon: Icons.directions_walk,
              color: const Color(0xFFFF5722), // Orange-red
              size: buttonSize,
              onTap: () {
                Navigator.pop(context);
                // Handle On Duty action
              },
            ),
            SizedBox(width: spacing),
            _buildRequestButton(
              context: context,
              title: AppStrings.overtime,
              icon: Icons.access_time_outlined,
              color: const Color(0xFF9C27B0), // Vibrant purple
              size: buttonSize,
              onTap: () {
                Navigator.pop(context);
                // Handle Overtime action
              },
            ),
            SizedBox(width: spacing),
            _buildRequestButton(
              context: context,
              title: AppStrings.compOff,
              icon: Icons.schedule,
              color: const Color(0xFF4CAF50), // Green
              size: buttonSize,
              onTap: () {
                Navigator.pop(context);
                // Handle Comp-Off action
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    final iconSize = size * 0.35; // Icon size relative to button size
    final fontSize = MediaQuery.of(context).size.width * 0.032; // Dynamic font size

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: iconSize,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
