import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../../features/authentication/presentation/bloc/auth_bloc/auth_bloc.dart';
import '../../features/authentication/presentation/bloc/auth_bloc/auth_event.dart';
import '../../features/authentication/presentation/bloc/auth_bloc/auth_state.dart';
import '../../features/authentication/presentation/pages/change_password_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/post/domain/usecases/get_post_menu_overview_usecase.dart';
import '../../features/post/domain/repositories/post_repository.dart';
import '../../features/post/presentation/bloc/post_bloc.dart';
import '../../features/post/presentation/cubit/post_menu_cubit.dart';
import '../../features/post/presentation/pages/post_actions_page.dart';
import '../../features/user/domain/entities/user_profile.dart';
import '../../features/user/presentation/bloc/user_profile_bloc.dart';
import '../../features/user/presentation/bloc/user_profile_state.dart';
import '../../features/home/presentation/cubit/home_page_cubit.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../constants/module_permissions.dart';
import '../utils/app_spacing.dart';
import '../utils/app_navigator.dart';
import 'common/app_avatar.dart';

/// App drawer with user header, menu options, and logout — fully responsive.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // ─── Layout helpers ────────────────────────────────────────────────────────

  /// Clamp drawer width: never narrower than 260 dp or wider than 340 dp,
  /// but also never more than 88 % of the screen width on tiny phones.
  static double _drawerWidth(double sw) => (sw * 0.82).clamp(260.0, 340.0);

  /// Scale a base size by the shorter screen dimension so the drawer feels
  /// proportional on phones, small tablets, and large tablets alike.
  static double _scale(double base, double shortSide) {
    // Reference design width ~360 dp
    final factor = (shortSide / 360.0).clamp(0.85, 1.25);
    return base * factor;
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;
    final shortSide = sw < sh ? sw : sh;

    // Font / icon scaling caps – prevents huge text from blowing the layout.
    // Wrap the entire drawer in a MediaQuery that limits textScaleFactor.
    return MediaQuery(
      data: mq.copyWith(
        textScaler: TextScaler.linear(
          mq.textScaler.scale(1.0).clamp(0.85, 1.15),
        ),
      ),
      child: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        width: _drawerWidth(sw),
        elevation: 8,
        child: Column(
          children: [
            _DrawerHeader(shortSide: shortSide),
            Expanded(child: _DrawerBody(shortSide: shortSide)),
            _LogoutTile(shortSide: shortSide),
            // Respect bottom system bar / home indicator
            SizedBox(height: mq.padding.bottom),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.shortSide});

  final double shortSide;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final avatarRadius = AppDrawer._scale(28, shortSide).clamp(22.0, 36.0);
    final hPad = AppDrawer._scale(18, shortSide).clamp(14.0, 22.0);
    final vPad = AppDrawer._scale(20, shortSide).clamp(16.0, 28.0);

    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, profileState) {
        final userProfileBloc = context.read<UserProfileBloc>();
        final UserProfile? profile =
            profileState is UserProfileLoaded
                ? profileState.profile
                : userProfileBloc.lastKnownProfile;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(hPad, mq.padding.top + vPad, hPad, vPad),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppAvatar(
                  imageUrl: profile?.user.imageUrl,
                  name: profile?.user.fullName,
                  firstName: profile?.user.firstName,
                  lastName: profile?.user.lastName,
                  radius: avatarRadius,
                  backgroundColor: AppColors.background,
                ),
                SizedBox(width: AppDrawer._scale(14, shortSide)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          profile?.user.fullName ?? 'User',
                          style: AppTextStyles.heading3(context).copyWith(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: AppDrawer._scale(
                              17,
                              shortSide,
                            ).clamp(14.0, 20.0),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      SizedBox(height: AppDrawer._scale(3, shortSide)),
                      Text(
                        profile?.userDesignation?.designationName ??
                            profile?.user.employeeType ??
                            'Employee',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.textWhite.withValues(alpha: 0.90),
                          fontSize: AppDrawer._scale(
                            13,
                            shortSide,
                          ).clamp(11.0, 15.0),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Body (scrollable list) ─────────────────────────────────────────────────────

class _DrawerBody extends StatelessWidget {
  const _DrawerBody({required this.shortSide});

  final double shortSide;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, profileState) {
        final userProfileBloc = context.read<UserProfileBloc>();
        final profile =
            profileState is UserProfileLoaded
                ? profileState.profile
                : userProfileBloc.lastKnownProfile;
        final currentUserId = profile?.user.id;
        final permissions = profile?.role?.permissions ?? const <String>[];
        final showPostItems = ModulePermissions.postRead.any(
          permissions.contains,
        );
        final showActions = ModulePermissions.postAdmin.any(
          permissions.contains,
        );

        if (currentUserId == null) {
          return _DrawerMenuList(
            shortSide: shortSide,
            onLikedPostsTap: () => _showProfileUnavailableMessage(context),
            onRepostedPostsTap: () => _showProfileUnavailableMessage(context),
            onActionsTap: () => _showProfileUnavailableMessage(context),
            showPostItems: false,
            showActions: false,
          );
        }

        return BlocProvider(
          create:
              (_) => PostMenuCubit(
                getPostMenuOverviewUseCase:
                    context.read<GetPostMenuOverviewUseCase>(),
                currentUserId: currentUserId,
              )..fetchOverview(),
          child: BlocBuilder<PostMenuCubit, PostMenuState>(
            builder: (context, state) {
              return _DrawerMenuList(
                shortSide: shortSide,
                likedPostsCount: state.overview?.likedPostsCount,
                repostedPostsCount: state.overview?.repostedPostsCount,
                reportedPostsCount: state.overview?.reportedPostsCount,
                pendingApprovalPostsCount:
                    state.overview?.pendingApprovalPostsCount,
                onLikedPostsTap:
                    () => _openPostsFeed(context, postName: 'liked'),
                onRepostedPostsTap:
                    () => _openPostsFeed(
                      context,
                      postName: 'my',
                      onlyRepostedByCurrentUser: true,
                      repostedByUserId: currentUserId,
                    ),
                onActionsTap: () => _openActionsPage(context),
                showPostItems: showPostItems,
                showActions: showActions,
              );
            },
          ),
        );
      },
    );
  }

  void _openPostsFeed(
    BuildContext context, {
    required String postName,
    bool onlyRepostedByCurrentUser = false,
    int? repostedByUserId,
  }) {
    final homePageCubit = context.read<HomePageCubit>();
    final postBloc = context.read<PostBloc>();
    Navigator.pop(context);
    Future<void>.microtask(() {
      homePageCubit.switchTab(1);
      postBloc.add(
        FetchPostsEvent(
          postName: postName,
          onlyRepostedByCurrentUser: onlyRepostedByCurrentUser,
          repostedByUserId: repostedByUserId,
        ),
      );
    });
  }

  void _openActionsPage(BuildContext context) {
    final navigator = Navigator.of(context);
    final postRepository = context.read<PostRepository>();

    Navigator.pop(context);
    Future<void>.microtask(
      () => navigator.push(
        MaterialPageRoute(
          builder:
              (_) => PostActionsPage.withDependencies(
                postRepository: postRepository,
              ),
        ),
      ),
    );
  }

  void _showProfileUnavailableMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User profile is still loading. Please try again.'),
      ),
    );
  }
}

class _DrawerMenuList extends StatelessWidget {
  final double shortSide;
  final int? likedPostsCount;
  final int? repostedPostsCount;
  final int? reportedPostsCount;
  final int? pendingApprovalPostsCount;
  final VoidCallback onLikedPostsTap;
  final VoidCallback onRepostedPostsTap;
  final VoidCallback onActionsTap;
  final bool showPostItems;
  final bool showActions;

  const _DrawerMenuList({
    required this.shortSide,
    required this.onLikedPostsTap,
    required this.onRepostedPostsTap,
    required this.onActionsTap,
    required this.showPostItems,
    required this.showActions,
    this.likedPostsCount,
    this.repostedPostsCount,
    this.reportedPostsCount,
    this.pendingApprovalPostsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: ListView(
        padding: EdgeInsets.symmetric(
          vertical: AppDrawer._scale(10, shortSide),
        ),
        children: [
          if (showPostItems)
            _MenuTile(
              icon: Icons.favorite_border_rounded,
              iconColor: AppColors.attendanceTeal,
              label: AppStrings.likedPosts,
              shortSide: shortSide,
              trailing:
                  likedPostsCount == null
                      ? null
                      : _MenuCountBadge(count: likedPostsCount!),
              onTap: onLikedPostsTap,
            ),
          if (showPostItems)
            _MenuTile(
              icon: Icons.repeat_rounded,
              iconColor: AppColors.attendanceTeal,
              label: AppStrings.repostedPosts,
              shortSide: shortSide,
              trailing:
                  repostedPostsCount == null
                      ? null
                      : _MenuCountBadge(count: repostedPostsCount!),
              onTap: onRepostedPostsTap,
            ),
          if (showActions)
            _MenuTile(
              icon: Icons.pending_actions_outlined,
              iconColor: AppColors.attendanceTeal,
              label: AppStrings.actions,
              shortSide: shortSide,
              trailing:
                  reportedPostsCount == null || pendingApprovalPostsCount == null
                      ? null
                      : _ActionCountsBadge(
                        reportedCount: reportedPostsCount!,
                        pendingCount: pendingApprovalPostsCount!,
                      ),
              onTap: onActionsTap,
            ),
          _MenuTile(
            icon: Icons.lock_outline,
            iconColor: AppColors.attendanceTeal,
            label: AppStrings.changePassword,
            shortSide: shortSide,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
              );
            },
          ),
          _ProfileInfoCard(shortSide: shortSide),
        ],
      ),
    );
  }
}

// ─── Profile info card ──────────────────────────────────────────────────────────

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.shortSide});

  final double shortSide;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, profileState) {
        final userProfileBloc = context.read<UserProfileBloc>();
        final profile =
            profileState is UserProfileLoaded
                ? profileState.profile
                : userProfileBloc.lastKnownProfile;
        if (profile == null) return const SizedBox.shrink();

        final infoItems = <_ProfileInfoItem>[
          if ((profile.user.email ?? '').isNotEmpty)
            _ProfileInfoItem(
              AppStrings.email,
              profile.user.email!,
              Icons.alternate_email_rounded,
            ),
          if ((profile.userDesignation?.designationName ?? '').isNotEmpty)
            _ProfileInfoItem(
              AppStrings.designation,
              profile.userDesignation!.designationName!,
              Icons.badge_outlined,
            ),
          if ((profile.user.employeeID ?? '').isNotEmpty)
            _ProfileInfoItem(
              AppStrings.employeeId,
              profile.user.employeeID!,
              Icons.perm_identity_rounded,
            ),
          if ((profile.user.phone ?? '').isNotEmpty)
            _ProfileInfoItem(
              AppStrings.phoneNo,
              profile.user.phone!,
              Icons.call_outlined,
            ),
          if ((profile.user.gender ?? '').isNotEmpty)
            _ProfileInfoItem(
              AppStrings.gender,
              profile.user.gender!,
              Icons.wc_outlined,
            ),
          if ((profile.user.location ?? '').isNotEmpty)
            _ProfileInfoItem(
              AppStrings.location,
              profile.user.location!,
              Icons.location_on_outlined,
            ),
        ];

        if (infoItems.isEmpty) return const SizedBox.shrink();

        final hMargin = AppDrawer._scale(14, shortSide).clamp(10.0, 18.0);
        final cardPad = AppDrawer._scale(14, shortSide).clamp(10.0, 18.0);
        final itemSpacing = AppDrawer._scale(12, shortSide).clamp(8.0, 16.0);

        return Container(
          margin: EdgeInsets.fromLTRB(hMargin, 6, hMargin, 0),
          padding: EdgeInsets.all(cardPad),
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
            children:
                infoItems.asMap().entries.map((entry) {
                  final isLast = entry.key == infoItems.length - 1;
                  final item = entry.value;
                  final row =
                      item.label == 'Phone No'
                          ? _PhoneRow(phone: item.value, shortSide: shortSide)
                          : _InfoRow(
                            icon: item.icon,
                            label: item.label,
                            value: item.value,
                            shortSide: shortSide,
                          );
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : itemSpacing),
                    child: row,
                  );
                }).toList(),
          ),
        );
      },
    );
  }
}

// ─── Individual info row ────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.shortSide,
  });

  final IconData icon;
  final String label;
  final String value;
  final double shortSide;

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = AppDrawer._scale(32, shortSide).clamp(26.0, 38.0);
    final iconSize = AppDrawer._scale(16, shortSide).clamp(13.0, 20.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: iconSize, color: AppColors.attendanceTeal),
        ),
        SizedBox(width: AppDrawer._scale(10, shortSide)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: AppDrawer._scale(10.5, shortSide).clamp(9.0, 12.0),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: AppDrawer._scale(13, shortSide).clamp(11.0, 15.0),
                  height: 1.35,
                ),
                // Prevent long values (e.g. emails) from overflowing
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Phone row (async formatting) ──────────────────────────────────────────────

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.phone, required this.shortSide});

  final String phone;
  final double shortSide;

  Future<String> _format(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return raw;
    try {
      final info = await PhoneNumber.getRegionInfoFromPhoneNumber(
        trimmed,
        'IN',
      );
      final formatted = info.phoneNumber ?? trimmed;
      final match = RegExp(
        r'^\+91(\d{5})(\d{5})$',
      ).firstMatch(formatted.replaceAll(' ', ''));
      return match != null
          ? '+91 ${match.group(1)} ${match.group(2)}'
          : formatted;
    } catch (_) {
      return trimmed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _format(phone),
      builder:
          (context, snap) => _InfoRow(
            icon: Icons.call_outlined,
            label: 'Phone No',
            value: snap.data ?? phone,
            shortSide: shortSide,
          ),
    );
  }
}

// ─── Menu tile ──────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    required this.shortSide,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final double shortSide;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final hPad = AppDrawer._scale(18, shortSide).clamp(14.0, 22.0);
    final vPad = AppDrawer._scale(13, shortSide).clamp(10.0, 16.0);
    final iconSize = AppDrawer._scale(22, shortSide).clamp(18.0, 26.0);
    final fontSize = AppDrawer._scale(15, shortSide).clamp(13.0, 17.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: iconSize),
              SizedBox(width: AppDrawer._scale(14, shortSide)),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: AppDrawer._scale(12, shortSide)),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCountBadge extends StatelessWidget {
  final int count;

  const _MenuCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.attendanceTeal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.labelSmall(context).copyWith(
          color: AppColors.attendanceTeal,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionCountsBadge extends StatelessWidget {
  final int reportedCount;
  final int pendingCount;

  const _ActionCountsBadge({
    required this.reportedCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LabeledCountBadge(
          label: 'R',
          count: reportedCount,
          color: AppColors.error,
        ),
        AppSpacing.hXs,
        _LabeledCountBadge(
          label: 'P',
          count: pendingCount,
          color: AppColors.info,
        ),
      ],
    );
  }
}

class _LabeledCountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _LabeledCountBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Text(
        '$label $count',
        style: AppTextStyles.labelSmall(
          context,
        ).copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── Logout tile ────────────────────────────────────────────────────────────────

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.shortSide});

  final double shortSide;

  @override
  Widget build(BuildContext context) {
    final hPad = AppDrawer._scale(18, shortSide).clamp(14.0, 22.0);
    final vPad = AppDrawer._scale(14, shortSide).clamp(10.0, 18.0);
    final iconSize = AppDrawer._scale(22, shortSide).clamp(18.0, 26.0);
    final fontSize = AppDrawer._scale(15, shortSide).clamp(13.0, 17.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleLogout(context),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: iconSize,
                ),
                SizedBox(width: AppDrawer._scale(14, shortSide)),
                Expanded(
                  child: Text(
                    AppStrings.logout,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final navigatorContext = AppNavigator.navigatorKey.currentContext;
    if (navigatorContext == null) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
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

    if (!context.mounted) return;
    Navigator.pop(context); // Close drawer

    if (shouldLogout == true && navigatorContext.mounted) {
      navigatorContext.read<AuthBloc>().add(const LogoutRequested());
      final state = await navigatorContext.read<AuthBloc>().stream.firstWhere(
        (s) => s is AuthUnauthenticated || s is AuthError,
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
  }
}

// ─── Data class ────────────────────────────────────────────────────────────────

class _ProfileInfoItem {
  const _ProfileInfoItem(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}
