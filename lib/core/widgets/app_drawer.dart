import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/authentication/presentation/bloc/auth_bloc/auth_bloc.dart';
import '../../features/authentication/presentation/bloc/auth_bloc/auth_event.dart';
import '../../features/authentication/presentation/bloc/auth_bloc/auth_state.dart';
import '../../features/authentication/presentation/pages/change_password_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/user/domain/entities/user_profile.dart';
import '../../features/user/presentation/bloc/user_profile_bloc.dart';
import '../../features/user/presentation/bloc/user_profile_state.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../utils/app_navigator.dart';
import 'common/app_avatar.dart';

/// App drawer with user header, menu options, and logout
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      width: MediaQuery.of(context).size.width * 0.82,
      elevation: 8,
      child: Column(
        children: [
          // Header with user name and position
          BlocBuilder<UserProfileBloc, UserProfileState>(
            builder: (context, profileState) {
              final UserProfile? profile =
                  profileState is UserProfileLoaded ? profileState.profile : null;

              return Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 20,
                  20,
                  24,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.attendanceTeal,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.attendanceBorderBlue,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      AppAvatar(
                        imageUrl: profile?.user.imageUrl,
                        name: profile?.user.fullName,
                        radius: 30,
                        backgroundColor: AppColors.background,
                        icon: Icons.person,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              profile?.user.firstName ?? 'User',
                              style: AppTextStyles.heading3(context).copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile?.userDesignation?.designationName ??
                                  profile?.user.employeeType ??
                                  'Employee',
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                color: AppColors.textWhite.withValues(alpha: 0.95),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Menu items
          Expanded(
            child: Container(
              color: AppColors.background,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.lock_outline,
                    iconColor: AppColors.attendanceTeal,
                    label: AppStrings.changePassword,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),
                  BlocBuilder<UserProfileBloc, UserProfileState>(
                    builder: (context, profileState) {
                      final profile =
                          profileState is UserProfileLoaded
                              ? profileState.profile
                              : null;

                      if (profile == null) {
                        return const SizedBox.shrink();
                      }

                      final infoItems = <_ProfileInfoItem>[
                        if ((profile.user.email ?? '').isNotEmpty)
                          _ProfileInfoItem(
                            'Email',
                            profile.user.email!,
                            Icons.alternate_email_rounded,
                          ),
                        if ((profile.userDesignation?.designationName ?? '')
                            .isNotEmpty)
                          _ProfileInfoItem(
                            'Designation',
                            profile.userDesignation!.designationName!,
                            Icons.badge_outlined,
                          ),
                        if ((profile.user.employeeID ?? '').isNotEmpty)
                          _ProfileInfoItem(
                            'Employee Id',
                            profile.user.employeeID!,
                            Icons.perm_identity_rounded,
                          ),
                        if ((profile.user.phone ?? '').isNotEmpty)
                          _ProfileInfoItem(
                            'Phone No',
                            profile.user.phone!,
                            Icons.call_outlined,
                          ),
                        if ((profile.user.gender ?? '').isNotEmpty)
                          _ProfileInfoItem(
                            'Gender',
                            profile.user.gender!,
                            Icons.wc_outlined,
                          ),
                        if ((profile.user.location ?? '').isNotEmpty)
                          _ProfileInfoItem(
                            'Location',
                            profile.user.location!,
                            Icons.location_on_outlined,
                          ),
                      ];

                      if (infoItems.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: infoItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;

                            return Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        index == infoItems.length - 1 ? 0 : 14,
                                  ),
                                  child: _buildProfileInfoRow(
                                    context,
                                    item.icon,
                                    item.label,
                                    item.value,
                                  ),
                                );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Logout at bottom
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  // Use navigator context - drawer context gets disposed when we pop it
                  final navigatorContext =
                      AppNavigator.navigatorKey.currentContext;
                  if (navigatorContext == null) return;

                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text(AppStrings.logout),
                      content: const Text(AppStrings.logoutConfirmation),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(AppStrings.no),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(AppStrings.yes),
                        ),
                      ],
                    ),
                  );

                  Navigator.pop(context); // Close drawer

                  if (shouldLogout == true && navigatorContext.mounted) {
                    navigatorContext.read<AuthBloc>().add(const LogoutRequested());
                    final state = await navigatorContext
                        .read<AuthBloc>()
                        .stream
                        .firstWhere(
                          (s) =>
                              s is AuthUnauthenticated || s is AuthError,
                        );
                    if (navigatorContext.mounted) {
                      if (state is AuthUnauthenticated) {
                        Navigator.pushAndRemoveUntil(
                          navigatorContext,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      } else if (state is AuthError) {
                        ScaffoldMessenger.of(navigatorContext).showSnackBar(
                          SnackBar(
                            content: Text(state.failure.message),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        AppStrings.logout,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.attendanceTeal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoItem {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileInfoItem(
    this.label,
    this.value,
    this.icon,
  );
}
