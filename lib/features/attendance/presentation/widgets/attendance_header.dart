import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common/app_avatar.dart';
import '../../../user/domain/entities/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../notification/presentation/bloc/notification_bloc.dart';
import '../../../notification/presentation/bloc/notification_state.dart';
import '../../../notification/presentation/bloc/notification_event.dart';
import '../../../notification/presentation/pages/notifications_page.dart';

/// Attendance page header with profile and user info
class AttendanceHeader extends StatelessWidget {
  final UserProfile? userProfile;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onCalenderTap;

  const AttendanceHeader({
    super.key,
    this.userProfile,
    this.onAvatarTap,
    this.onCalenderTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.attendanceTeal, AppColors.attendancedarkbottom],
            stops: [0.55, 1.2], // 26.77% and 100%
          ),
          border: const Border(
            bottom: BorderSide(color: AppColors.attendanceBorderBlue, width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width *
                  0.042, // ~4.2% of screen width
              MediaQuery.of(context).size.height * 0.03, // 3% of screen height
              MediaQuery.of(context).size.width * 0.042,
              MediaQuery.of(context).size.height * 0.03,
            ),
            child: Row(
              children: [
                // Profile picture - tappable to open drawer
                GestureDetector(
                  onTap: onAvatarTap,
                  child: AppAvatar(
                    imageUrl: userProfile?.user.imageUrl,
                    name: userProfile?.user.fullName,
                    radius: 28,
                    backgroundColor: AppColors.background,
                    icon: Icons.person,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.032,
                ), // ~3.2% of screen width
                // Name and title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userProfile?.user.fullName ?? 'User',
                        style: AppTextStyles.heading3(
                          context,
                        ).copyWith(color: AppColors.textWhite, height: 1.2),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.005,
                      ), // 0.5% of screen height
                      Text(
                        userProfile?.userDesignation?.designationName ??
                            userProfile?.user.employeeType ??
                            'Employee',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.textWhite.withOpacity(0.9),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.011,
                ), // ~1.1% of screen width

                GestureDetector(
                  onTap: () {
                    context.read<NotificationBloc>().add(
                      MarkNotificationsAsViewed(),
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => BlocProvider.value(
                              value: context.read<NotificationBloc>(),
                              child: const NotificationsPage(),
                            ),
                      ),
                    ).then((_) {
                      if (context.mounted) {
                        context.read<NotificationBloc>().add(ClearNotificationCountLocally());
                        context.read<NotificationBloc>().add(FetchNotificationCount());
                      }
                    });
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 2),
                        child: SvgPicture.asset(AppAssets.iconnotification),
                      ),
                      BlocBuilder<NotificationBloc, NotificationState>(
                        builder: (context, state) {
                          int unreadCount = 0;
                          if (state is NotificationCountLoaded) {
                            unreadCount = state.count;
                          } else if (state is NotificationLoaded) {
                            unreadCount =
                                state.notifications
                                    .where((n) => !n.isRead)
                                    .length;
                          }

                          if (unreadCount > 0) {
                            return Positioned(
                              right: -6,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape:
                                      unreadCount > 9
                                          ? BoxShape.rectangle
                                          : BoxShape.circle,
                                  borderRadius:
                                      unreadCount > 9
                                          ? BorderRadius.circular(10)
                                          : null,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    unreadCount > 9
                                        ? '9+'
                                        : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
