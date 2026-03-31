import 'dart:ui';
import 'package:collectivWork/core/constants/module_permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../user/presentation/bloc/user_profile_state.dart';
import 'sub_requets/leaves/presentation/pages/apply_leave_page_listing.dart';
import 'sub_requets/wfh/presentation/pages/wfh_page_listing.dart';
import 'sub_requets/regularize/presentation/pages/regularize_page_listing.dart';
import 'sub_requets/on_duty/presentation/pages/on_duty_page_listing.dart';
import 'sub_requets/overtime/presentation/pages/overtime_page_listing.dart';
import 'sub_requets/comp_off/presentation/pages/comp_off_page_listing.dart';

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
    final iconSize =
        screenWidth * 0.12; // 12% of screen width for icon container
    final buttonSize =
        (screenWidth - (horizontalPadding * 2) - (screenWidth * 0.06)) /
        3; // Dynamic button size
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
                child: Container(color: Colors.black.withValues(alpha: 0.3)),
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
                                  fontSize:
                                      screenWidth * 0.06, // 6% of screen width
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.requestDescription,
                                style: TextStyle(
                                  fontSize:
                                      screenWidth *
                                      0.035, // 3.5% of screen width
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: screenHeight * 0.03,
                    ), // 3% of screen height
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
    final actions = <_BottomSheetAction>[
      _BottomSheetAction(
        title: AppStrings.applyLeave,
        permissions: ModulePermissions.leaveRequest,
        icon: Icons.calendar_today_outlined,
        color: const Color(0xFFE91E63),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ApplyLeavePageListing(),
              ),
            ),
      ),
      _BottomSheetAction(
        title: AppStrings.wfh,
        permissions: ModulePermissions.wfhRequest,
        icon: Icons.home_outlined,
        color: const Color(0xFF1976D2),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WfhPageListing()),
            ),
      ),
      _BottomSheetAction(
        title: AppStrings.regularize,
        permissions: ModulePermissions.regularizeRequest,
        icon: Icons.check_circle_outline,
        color: const Color(0xFF9C27B0),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegularizePageListing(),
              ),
            ),
      ),
      _BottomSheetAction(
        title: AppStrings.onDuty,
        permissions: ModulePermissions.onDutyRequest,
        icon: Icons.directions_walk,
        color: const Color(0xFFFF5722),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OnDutyPageListing()),
            ),
      ),
      _BottomSheetAction(
        title: AppStrings.overtime,
        permissions: ModulePermissions.overtimeRequest,
        icon: Icons.access_time_outlined,
        color: const Color(0xFF9C27B0),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OvertimePageListing(),
              ),
            ),
      ),
      _BottomSheetAction(
        title: AppStrings.compOff,
        permissions: ModulePermissions.compOffRequest,
        icon: Icons.schedule,
        color: const Color(0xFF4CAF50),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CompOffPageListing()),
            ),
      ),
    ];

    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, state) {
        final permissions =
            state is UserProfileLoaded
                ? (state.profile.role?.permissions ?? const <String>[])
                : const <String>[];
        final visibleActions =
            actions
                .where((action) => action.permissions.any(permissions.contains))
                .toList();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              visibleActions.map((action) {
                return SizedBox(
                  width: buttonSize,
                  child: _buildRequestButton(
                    context: context,
                    title: action.title,
                    icon: action.icon,
                    color: action.color,
                    size: buttonSize,
                    onTap: () {
                      Navigator.pop(context);
                      action.onTap();
                    },
                  ),
                );
              }).toList(),
        );
      },
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
    final fontSize =
        MediaQuery.of(context).size.width * 0.032; // Dynamic font size

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
            child: Icon(icon, color: Colors.white, size: iconSize),
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

class _BottomSheetAction {
  final String title;
  final List<String> permissions;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BottomSheetAction({
    required this.title,
    required this.permissions,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
