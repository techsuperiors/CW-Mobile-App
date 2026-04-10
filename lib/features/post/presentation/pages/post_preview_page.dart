import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/api_error_state.dart';
import '../../../../features/user/presentation/bloc/user_profile_bloc.dart';
import '../../../../features/user/presentation/bloc/user_profile_state.dart';
import '../../domain/entities/announcement_entity.dart';
import '../Widgets/post_card_widget.dart';
import '../bloc/post_bloc.dart';

class PostPreviewPage extends StatelessWidget {
  const PostPreviewPage({super.key});

  void _refreshPost(BuildContext context, {bool showLoader = false}) {
    context.read<PostBloc>().add(RefreshPostsEvent(showLoader: showLoader));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth=MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar:
      AppBar(
        forceMaterialTransparency: true,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
                size: screenWidth * 0.048,
              ),
              Flexible(
                child: Text(
                  AppStrings.back,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 110,
        title: Text(
          AppStrings.postPreview,
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      // AppBar(
      //   backgroundColor: AppColors.background,
      //   foregroundColor: AppColors.textPrimary,
      //   elevation: 0,
      //   forceMaterialTransparency: true,
      //   title: Text(
      //     AppStrings.postPreview,
      //     style: AppTextStyles.heading4(
      //       context,
      //     ).copyWith(fontWeight: FontWeight.w600),
      //   ),
      // ),
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<PostBloc, PostState>(
          listener: (context, state) {
            if (state is PostLoaded && state.actionMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
            }
            if (state is PostLoaded && state.actionErrorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.actionErrorMessage!)),
              );
            }
          },
          builder: (context, state) {
            if (state is PostLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PostError) {
              return ApiErrorState(
                rawMessage: state.message,
                title: 'Unable to load post',
                onRetry: () => _refreshPost(context, showLoader: true),
              );
            }

            if (state is! PostLoaded || state.announcements.isEmpty) {
              return const ApiErrorState(
                rawMessage: null,
                title: 'Post not found',
                description: 'This post is unavailable right now.',
              );
            }

            return _PostPreviewContent(
              announcements: state.announcements,
              processingPostIds: state.processingPostIds,
              onRefresh: () => _refreshPost(context),
            );
          },
        ),
      ),
    );
  }
}

class _PostPreviewContent extends StatelessWidget {
  final List<AnnouncementEntity> announcements;
  final List<int> processingPostIds;
  final VoidCallback onRefresh;

  const _PostPreviewContent({
    required this.announcements,
    required this.processingPostIds,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, userState) {
        final int? currentUserId =
            userState is UserProfileLoaded ? userState.profile.userId : null;
        final CreatedByUserEntity? currentUser =
            userState is UserProfileLoaded
                ? CreatedByUserEntity(
                  id: userState.profile.userId,
                  firstName: userState.profile.user.firstName ?? '',
                  lastName: userState.profile.user.lastName ?? '',
                  imageUrl: userState.profile.user.imageUrl,
                  profileColor: userState.profile.user.profileColor,
                )
                : null;

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            itemCount: announcements.length,
            separatorBuilder: (_, __) => AppSpacing.vMd,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return PostCard(
                announcement: announcement,
                currentUserId: currentUserId,
                currentUser: currentUser,
                isReactionProcessing: processingPostIds.contains(
                  announcement.id,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
