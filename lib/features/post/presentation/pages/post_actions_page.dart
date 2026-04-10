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
import '../../domain/repositories/post_repository.dart';
import '../../domain/usecases/bookmark_announcement_usecase.dart';
import '../../domain/usecases/delete_announcement_usecase.dart';
import '../../domain/usecases/get_announcement_details_usecase.dart';
import '../../domain/usecases/get_announcements_usecase.dart';
import '../../domain/usecases/like_announcement_usecase.dart';
import '../../domain/usecases/mark_announcement_admin_remark_usecase.dart';
import '../../domain/usecases/report_announcement_usecase.dart';
import '../../domain/usecases/repost_announcement_usecase.dart';
import '../../domain/usecases/remove_like_usecase.dart';
import '../../domain/usecases/remove_bookmark_usecase.dart';
import '../../domain/usecases/remove_repost_usecase.dart';
import '../../domain/usecases/submit_poll_answer_usecase.dart';
import '../../domain/usecases/update_announcement_usecase.dart';
import '../Widgets/post_card_widget.dart';
import '../bloc/post_bloc.dart';

enum PostActionsTab {
  pendingApproval(
    postName: 'pending_approval',
    label: AppStrings.pendingApproval,
    emptyMessage: 'No pending approval posts yet.',
    errorTitle: 'Unable to load pending approvals',
  ),
  reportedPosts(
    postName: 'report',
    label: AppStrings.reportedPosts,
    emptyMessage: 'No reported posts yet.',
    errorTitle: 'Unable to load reported posts',
  );

  final String postName;
  final String label;
  final String emptyMessage;
  final String errorTitle;

  const PostActionsTab({
    required this.postName,
    required this.label,
    required this.emptyMessage,
    required this.errorTitle,
  });
}

class PostActionsPage extends StatefulWidget {
  final PostActionsTab initialTab;

  const PostActionsPage({
    super.key,
    this.initialTab = PostActionsTab.pendingApproval,
  });

  static Widget withDependencies({
    required PostRepository postRepository,
    PostActionsTab initialTab = PostActionsTab.pendingApproval,
  }) {
    return BlocProvider(
      create:
          (_) =>
              _createPostBloc(postRepository)
                ..add(FetchPostsEvent(postName: initialTab.postName)),
      child: PostActionsPage(initialTab: initialTab),
    );
  }

  static PostBloc _createPostBloc(PostRepository postRepository) {
    return PostBloc(
      getAnnouncementsUseCase: GetAnnouncementsUseCase(postRepository),
      getAnnouncementDetailsUseCase: GetAnnouncementDetailsUseCase(
        postRepository,
      ),
      bookmarkAnnouncementUseCase: BookmarkAnnouncementUseCase(postRepository),
      removeBookmarkUseCase: RemoveBookmarkUseCase(postRepository),
      likeAnnouncementUseCase: LikeAnnouncementUseCase(postRepository),
      markAnnouncementAdminRemarkUseCase: MarkAnnouncementAdminRemarkUseCase(
        postRepository,
      ),
      reportAnnouncementUseCase: ReportAnnouncementUseCase(postRepository),
      removeLikeUseCase: RemoveLikeUseCase(postRepository),
      submitPollAnswerUseCase: SubmitPollAnswerUseCase(postRepository),
      repostAnnouncementUseCase: RepostAnnouncementUseCase(postRepository),
      removeRepostUseCase: RemoveRepostUseCase(postRepository),
      deleteAnnouncementUseCase: DeleteAnnouncementUseCase(postRepository),
      updateAnnouncementUseCase: UpdateAnnouncementUseCase(postRepository),
    );
  }

  @override
  State<PostActionsPage> createState() => _PostActionsPageState();
}

class _PostActionsPageState extends State<PostActionsPage> {
  late PostActionsTab _selectedTab = widget.initialTab;

  Future<void> _refreshCurrentTab({bool showLoader = false}) async {
    context.read<PostBloc>().add(RefreshPostsEvent(showLoader: showLoader));
  }

  void _onTabSelected(int index) {
    final nextTab = PostActionsTab.values[index];
    if (nextTab == _selectedTab) {
      return;
    }

    setState(() => _selectedTab = nextTab);
    context.read<PostBloc>().add(FetchPostsEvent(postName: nextTab.postName));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: PostActionsTab.values.length,
      initialIndex: _selectedTab.index,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.actions,
                        style: AppTextStyles.heading3(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.lg),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: TabBar(
                  onTap: _onTabSelected,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: AppTextStyles.bodyMediumHeading(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: AppTextStyles.bodyMediumHeading(
                    context,
                  ).copyWith(fontWeight: FontWeight.w500),
                  tabs: PostActionsTab.values
                      .map((tab) => Tab(text: tab.label))
                      .toList(growable: false),
                ),
              ),
              Expanded(
                child: BlocConsumer<PostBloc, PostState>(
                  listener: (context, state) {
                    if (state is PostLoaded && state.actionMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.actionMessage!)),
                      );
                    }
                    if (state is PostLoaded &&
                        state.actionErrorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.actionErrorMessage!)),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is PostLoading || state is PostInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is PostError) {
                      return ApiErrorState(
                        rawMessage: state.message,
                        title: _selectedTab.errorTitle,
                        onRetry: () => _refreshCurrentTab(showLoader: true),
                      );
                    }

                    if (state is! PostLoaded || state.announcements.isEmpty) {
                      return _ActionsEmptyState(
                        message: _selectedTab.emptyMessage,
                      );
                    }

                    return _ActionsPostList(
                      announcements: state.announcements,
                      processingPostIds: state.processingPostIds,
                      selectedTab: _selectedTab,
                      onRefresh: _refreshCurrentTab,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionsPostList extends StatelessWidget {
  final List<AnnouncementEntity> announcements;
  final List<int> processingPostIds;
  final PostActionsTab selectedTab;
  final Future<void> Function({bool showLoader}) onRefresh;

  const _ActionsPostList({
    required this.announcements,
    required this.processingPostIds,
    required this.selectedTab,
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
          onRefresh: () => onRefresh(),
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
                adminActionMode:
                    selectedTab == PostActionsTab.pendingApproval
                        ? PostCardAdminActionMode.pendingApproval
                        : PostCardAdminActionMode.reportedPost,
              );
            },
          ),
        );
      },
    );
  }
}

class _ActionsEmptyState extends StatelessWidget {
  final String message;

  const _ActionsEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
      ),
    );
  }
}
