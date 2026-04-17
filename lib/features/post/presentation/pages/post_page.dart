import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:collectivWork/core/constants/module_permissions.dart';
import 'package:collectivWork/core/utils/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/permission_guard.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/usecases/bookmark_announcement_usecase.dart';
import '../../domain/usecases/delete_announcement_usecase.dart';
import '../../domain/usecases/get_announcement_details_usecase.dart';
import '../../domain/usecases/get_announcements_usecase.dart';
import '../../domain/usecases/get_bookmarked_announcements_usecase.dart';
import '../../domain/usecases/like_announcement_usecase.dart';
import '../../domain/usecases/mark_announcement_admin_remark_usecase.dart';
import '../../domain/usecases/report_announcement_usecase.dart';
import '../../domain/usecases/repost_announcement_usecase.dart';
import '../../domain/usecases/remove_like_usecase.dart';
import '../../domain/usecases/remove_bookmark_usecase.dart';
import '../../domain/usecases/remove_repost_usecase.dart';
import '../../domain/usecases/submit_poll_answer_usecase.dart';
import '../../domain/usecases/update_announcement_usecase.dart';
import '../bloc/bookmarked_posts_bloc.dart';
import '../bloc/post_bloc.dart';
import '../Widgets/create_post_type_sheet.dart';
import '../Widgets/general_post_composer_sheet.dart';
import '../Widgets/post_card_widget.dart';
import '../Widgets/poll_post_composer_sheet.dart';
import '../Widgets/praise_post_composer_sheet.dart';
import 'bookmarked_posts_page.dart';
import 'post_preview_page.dart';
import '../../../../features/user/presentation/bloc/user_profile_bloc.dart';
import '../../../../features/user/presentation/bloc/user_profile_state.dart';

class PostPage extends StatefulWidget {
  final String title;

  const PostPage({required this.title, super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  static const String _allPostsFilter = 'all';
  static const String _myPostsFilter = 'my';
  static const String _praisePostsFilter = 'praise';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, ScrollController> _scrollControllers = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  void _fetchPosts() {
    context.read<PostBloc>().add(const FetchPostsEvent());
  }

  void _refreshCurrentPosts({bool showLoader = false}) {
    context.read<PostBloc>().add(RefreshPostsEvent(showLoader: showLoader));
  }

  String _currentPostFilter() {
    final state = context.read<PostBloc>().state;
    if (state is PostLoaded) {
      return state.currentPostName;
    }
    return _allPostsFilter;
  }

  void _selectPostFilter(String postName) {
    if (_currentPostFilter() == postName) {
      return;
    }

    context.read<PostBloc>().add(
      FetchPostsEvent(postName: postName, showLoader: false),
    );
  }

  void _handleSearchChanged(String value) {
    final nextQuery = value.trimLeft();
    if (_searchQuery == nextQuery) {
      return;
    }

    setState(() {
      _searchQuery = nextQuery;
    });
  }

  ScrollController _scrollControllerFor(String postName) {
    return _scrollControllers.putIfAbsent(postName, ScrollController.new);
  }

  List<AnnouncementEntity> _filterAnnouncements(
    List<AnnouncementEntity> announcements,
  ) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return announcements;
    }

    return announcements
        .where((announcement) {
          final normalizedSubject = announcement.subject.trim().toLowerCase();
          final normalizedDescription =
              announcement.description.trim().toLowerCase();

          return normalizedSubject.contains(normalizedQuery) ||
              normalizedDescription.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  PostBloc _createPreviewPostBloc(PostRepository postRepository) {
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

  Future<void> _openAnnouncementPreview(int announcementId) async {
    final postRepository = context.read<PostRepository>();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => BlocProvider(
              create:
                  (_) => _createPreviewPostBloc(postRepository)..add(
                    FetchAnnouncementDetailsEvent(
                      announcementId: announcementId,
                    ),
                  ),
              child: const PostPreviewPage(),
            ),
      ),
    );
  }

  Future<void> _openBookmarkedPosts() async {
    final userState = context.read<UserProfileBloc>().state;
    if (userState is! UserProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load bookmarks right now.')),
      );
      return;
    }

    final postRepository = context.read<PostRepository>();
    final selectedAnnouncementId = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder:
            (_) => BlocProvider(
              create:
                  (_) => BookmarkedPostsBloc(
                    getBookmarkedAnnouncementsUseCase:
                        GetBookmarkedAnnouncementsUseCase(postRepository),
                    currentUserId: userState.profile.userId,
                  ),
              child: const BookmarkedPostsPage(),
            ),
      ),
    );

    if (!mounted || selectedAnnouncementId == null) return;

    await _openAnnouncementPreview(selectedAnnouncementId);
  }

  Future<void> _openCreatePostSheet() async {
    final audienceSelection = await showCreatePostTypeSheet(context);
    if (!mounted || audienceSelection == null) {
      return;
    }

    final userState = context.read<UserProfileBloc>().state;
    if (userState is! UserProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open composer right now.')),
      );
      return;
    }

    final message = await _openComposerForSelection(
      audienceSelection: audienceSelection,
      createdBy: userState.profile.userId,
    );

    if (!mounted || message == null || message.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    _refreshCurrentPosts(showLoader: false);
  }

  Future<String?> _openComposerForSelection({
    required CreatePostFlowResult audienceSelection,
    required int createdBy,
  }) {
    switch (audienceSelection.type) {
      case CreatePostType.general:
        return showGeneralPostComposerSheet(
          context,
          audience: audienceSelection,
          createdBy: createdBy,
        );
      case CreatePostType.praise:
        return showPraisePostComposerSheet(
          context,
          audience: audienceSelection,
          createdBy: createdBy,
        );
      case CreatePostType.poll:
        return showPollPostComposerSheet(
          context,
          audience: audienceSelection,
          createdBy: createdBy,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final horizontalPadding =
            maxWidth < 360
                ? 6.0
                : maxWidth > 600
                ? 24.0
                : 12.0;
        final contentMaxWidth = maxWidth > 900 ? 860.0 : double.infinity;
        final compact = maxWidth < 420;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(horizontalPadding),
                    _buildSearchAndFilter(
                      compact: compact,
                      horizontalPadding: horizontalPadding,
                    ),
                    Expanded(
                      child: BlocConsumer<PostBloc, PostState>(
                        listener: (context, state) {
                          if (state is PostLoaded &&
                              state.actionMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(state.actionMessage!)),
                            );
                          }
                          if (state is PostLoaded &&
                              state.actionErrorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.actionErrorMessage!),
                              ),
                            );
                          }
                        },
                        builder: (context, state) {
                          if (state is PostInitial || state is PostLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is PostLoaded) {
                            final filteredAnnouncements = _filterAnnouncements(
                              state.announcements,
                            );

                            if (filteredAnnouncements.isEmpty) {
                              return Center(
                                child: Text(
                                  _searchQuery.trim().isEmpty
                                      ? 'No posts found'
                                      : 'No matching posts found',
                                ),
                              );
                            }
                            return _buildPostList(
                              filteredAnnouncements,
                              currentPostName: state.currentPostName,
                              processingPostIds: state.processingPostIds,
                              horizontalPadding: horizontalPadding,
                            );
                          } else if (state is PostError) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding * 2,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Error: ${state.message}',
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed:
                                          () => _refreshCurrentPosts(
                                            showLoader: true,
                                          ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 4),
      child: Row(
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 360 ? 22 : 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textHeading,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter({
    required bool compact,
    required double horizontalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: AppSpacing.sm,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildSearchField(compact),
            AppSpacing.vSm,
            _buildPostTypeTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(bool compact) {
    return Row(
      children: [
        Expanded(child: _buildSearchInput()),
        AppSpacing.hMd,
        _buildSearchActions(),
      ],
    );
  }

  Widget _buildSearchInput() {
    return SizedBox(
      height: AppSpacing.section,
      child: TextField(
        controller: _searchController,
        onChanged: _handleSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search',
          fillColor: AppColors.backgroundMedium,
          filled: true,
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
      ),
    );
  }

  Widget _buildSearchActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _openBookmarkedPosts,
          child: SvgPicture.asset(
            AppAssets.bookmarksIcon,
            width: AppSpacing.iconMediumWidth,
            height: AppSpacing.iconMediumHeight,
          ),
        ),
        AppSpacing.hSm,
        PermissionGuard(
          anyOf: ModulePermissions.postWrite,
          child: GestureDetector(
            onTap: () {
              _openCreatePostSheet();
            },
            child: SvgPicture.asset(
              AppAssets.addIcon,
              width: AppSpacing.iconMediumWidth,
              height: AppSpacing.iconMediumHeight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostTypeTabs() {
    return BlocBuilder<PostBloc, PostState>(
      builder: (context, state) {
        final currentPostName =
            state is PostLoaded ? state.currentPostName : _allPostsFilter;
        final allPostsCount = state is PostLoaded ? state.allPostsCount : 0;
        final myPostsCount = state is PostLoaded ? state.myPostsCount : 0;
        final praisePostsCount =
            state is PostLoaded ? state.praisePostsCount : 0;

        return Row(
          children: [
            Expanded(
              child: _PostTypeTab(
                label: 'All Posts',
                count: allPostsCount,
                postIcons: AppAssets.allPostIcon,
                color: AppColors.info,
                isSelected: currentPostName == _allPostsFilter,
                onTap: () => _selectPostFilter(_allPostsFilter),
              ),
            ),
            AppSpacing.hSm,
            Expanded(
              child: _PostTypeTab(
                label: 'My Posts',
                count: myPostsCount,
                postIcons: AppAssets.myProfileIcon,
                color: AppColors.servicePurpleDark,
                isSelected: currentPostName == _myPostsFilter,
                onTap: () => _selectPostFilter(_myPostsFilter),
              ),
            ),
            AppSpacing.hSm,
            Expanded(
              child: _PostTypeTab(
                label: 'Praise',
                count: praisePostsCount,
                postIcons: AppAssets.praiseIcon,
                color: AppColors.error,
                isSelected: currentPostName == _praisePostsFilter,
                onTap: () => _selectPostFilter(_praisePostsFilter),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostList(
    List<AnnouncementEntity> announcements, {
    required String currentPostName,
    required List<int> processingPostIds,
    required double horizontalPadding,
  }) {
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
          onRefresh: () async {
            _refreshCurrentPosts();
          },
          child: ListView.builder(
            key: PageStorageKey<String>('post_list_$currentPostName'),
            controller: _scrollControllerFor(currentPostName),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              return PostCard(
                announcement: announcements[index],
                currentUserId: currentUserId,
                currentUser: currentUser,
                isReactionProcessing: processingPostIds.contains(
                  announcements[index].id,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PostTypeTab extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final String postIcons;

  const _PostTypeTab({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.postIcons,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? color : Colors.transparent,
                width: AppSpacing.xs / 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  height: AppSpacing.iconSmallHeight,
                  width: AppSpacing.iconSmallWidth,
                  child: SvgPicture.asset(postIcons)),
              AppSpacing.hSm,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.xl),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
