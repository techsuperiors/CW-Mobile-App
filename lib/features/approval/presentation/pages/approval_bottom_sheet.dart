import 'dart:ui';
import 'package:collectivWork/core/constants/module_permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../user/presentation/bloc/user_profile_state.dart';
import '../pages/sub_approvals/comp_off/comp_off_approval_page_listing.dart';
import '../pages/sub_approvals/leaves/leave_approval_page_listing.dart';
import '../pages/sub_approvals/on_duty/on_duty_approval_page_listing.dart';
import '../pages/sub_approvals/overtime/overtime_approval_page_listing.dart';
import '../pages/sub_approvals/regularize/regularize_approval_page_listing.dart';
import '../pages/sub_approvals/wfh/wfh_approval_page_listing.dart';


/// Request bottom sheet widget
class ApprovalBottomSheet extends StatelessWidget {
  const ApprovalBottomSheet({super.key});

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
                                AppStrings.approval,
                                style: TextStyle(
                                  fontSize:
                                      screenWidth * 0.06, // 6% of screen width
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.approvalDescription,
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
    final actions = <_ApprovalAction>[
      _ApprovalAction(
        title: AppStrings.applyLeave,
        permissions: ModulePermissions.leaveApproval,
        icon: Icons.calendar_today_outlined,
        color: const Color(0xFFE91E63),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LeaveApprovalPageListing(),
              ),
            ),
      ),
      _ApprovalAction(
        title: AppStrings.wfh,
        permissions: ModulePermissions.wfhApproval,
        icon: Icons.home_outlined,
        color: const Color(0xFF1976D2),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WfhApprovalPageListing(),
              ),
            ),
      ),
      _ApprovalAction(
        title: AppStrings.regularize,
        permissions: ModulePermissions.regularizeApproval,
        icon: Icons.check_circle_outline,
        color: const Color(0xFF9C27B0),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegularizeApprovalPageListing(),
              ),
            ),
      ),
      _ApprovalAction(
        title: AppStrings.onDuty,
        permissions: ModulePermissions.onDutyApproval,
        icon: Icons.directions_walk,
        color: const Color(0xFFFF5722),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OnDutyApprovalPageListing(),
              ),
            ),
      ),
      _ApprovalAction(
        title: AppStrings.overtime,
        permissions: ModulePermissions.overtimeApproval,
        icon: Icons.access_time_outlined,
        color: const Color(0xFF9C27B0),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OvertimeApprovalPageListing(),
              ),
            ),
      ),
      _ApprovalAction(
        title: AppStrings.compOff,
        permissions: ModulePermissions.compOffApproval,
        icon: Icons.schedule,
        color: const Color(0xFF4CAF50),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CompOffApprovalPageListing(),
              ),
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

class _ApprovalAction {
  final String title;
  final List<String> permissions;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ApprovalAction({
    required this.title,
    required this.permissions,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
