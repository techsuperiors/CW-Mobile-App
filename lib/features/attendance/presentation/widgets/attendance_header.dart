import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common/app_avatar.dart';
import '../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../user/presentation/bloc/user_profile_state.dart';

/// Attendance page header with profile and user info
class AttendanceHeader extends StatelessWidget {
  const AttendanceHeader({super.key});

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
            colors: [
              AppColors.attendanceTeal,
              AppColors.backgroundDark,
            ],
            stops: [0.2677, 1.0], // 26.77% and 100%
          ),
          border: const Border(
            bottom: BorderSide(
              color: AppColors.attendanceBorderBlue,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.042, // ~4.2% of screen width
              MediaQuery.of(context).size.height * 0.03, // 3% of screen height
              MediaQuery.of(context).size.width * 0.042,
              MediaQuery.of(context).size.height * 0.03,
            ),
            child: Row(
              children: [
                // Profile picture
                BlocBuilder<UserProfileBloc, UserProfileState>(
                  builder: (context, state) {
                    String? imageUrl;
                    String? userName;
                    
                    if (state is UserProfileLoaded) {
                      imageUrl = state.profile.user.imageUrl;
                      userName = state.profile.user.fullName;
                    }
                    
                    return AppAvatar(
                      imageUrl: imageUrl,
                      name: userName,
                      radius: 28,
                      backgroundColor: AppColors.background,
                      icon: Icons.person,
                    );
                  },
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.032), // ~3.2% of screen width
                // Name and title
                Expanded(
                  child: BlocBuilder<UserProfileBloc, UserProfileState>(
                    builder: (context, state) {
                      String userName = 'User';
                      String userDesignation = 'Employee';
                      
                      if (state is UserProfileLoaded) {
                        userName = state.profile.user.fullName;
                        userDesignation = state.profile.userDesignation?.designationName ?? 
                                         state.profile.user.employeeType ?? 
                                         'Employee';
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName,
                            style: AppTextStyles.heading3(context).copyWith(
                              color: AppColors.textWhite,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.005), // 0.5% of screen height
                          Text(
                            userDesignation,
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: AppColors.textWhite.withOpacity(0.9),
                              height: 1.2,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Calendar and notification icons
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: const Icon(
                    Icons.calendar_today,
                    color: AppColors.textWhite,
                    size: 24,
                  ),
                  onPressed: () {},
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.011), // ~1.1% of screen width
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textWhite,
                    size: 24,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

