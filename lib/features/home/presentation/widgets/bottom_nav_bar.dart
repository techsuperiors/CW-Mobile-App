import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/module_permissions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../user/presentation/bloc/user_profile_state.dart';

/// Bottom navigation bar
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Teal color for active items (matching the design)
    const activeColor = Color(0xFF009688);
    // Grey color for inactive items
    const inactiveColor = Color(0xFF757575);

    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, state) {
        final permissions =
            state is UserProfileLoaded
                ? (state.profile.role?.permissions ?? const <String>[])
                : const <String>[];
        final showPosts = ModulePermissions.postRead.any(permissions.contains);
        final showApproval = ModulePermissions.anyApprovalAccess.any(
          permissions.contains,
        );

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: AppAssets.iconServices,
                    isSvgIcon: true,
                    label: AppStrings.services,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  if (showPosts)
                    _buildNavItem(
                      index: 1,
                      icon: AppAssets.iconPosts,
                      isSvgIcon: true,
                      label: AppStrings.posts,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                  _buildNavItem(
                    index: 2,
                    icon: AppAssets.iconHome,
                    isSvgIcon: true,
                    label: AppStrings.home,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: AppAssets.iconRequest,
                    isSvgIcon: true,
                    label: AppStrings.request,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  if (showApproval)
                    _buildNavItem(
                      index: 4,
                      icon: AppAssets.iconApproval,
                      isSvgIcon: true,
                      label: AppStrings.approval,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required dynamic icon, // Can be String (for SVG) or IconData
    required bool isSvgIcon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isSelected = currentIndex == index;
    final itemColor = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            if (isSvgIcon)
              SvgPicture.asset(
                icon as String,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(itemColor, BlendMode.srcIn),
              )
            else
              Icon(icon as IconData, size: 22, color: itemColor),
            const SizedBox(height: 6),
            // Label
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
