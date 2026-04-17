import 'package:cached_network_image/cached_network_image.dart';
import 'package:collectivWork/core/constants/app_colors.dart';
import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:collectivWork/core/constants/app_text_styles.dart';
import 'package:collectivWork/core/utils/app_spacing.dart';
import 'package:collectivWork/features/post/domain/repositories/post_repository.dart';
import 'package:collectivWork/features/post/domain/usecases/add_comment_usecase.dart';
import 'package:collectivWork/features/post/domain/usecases/delete_comment_usecase.dart';
import 'package:collectivWork/features/post/domain/usecases/react_to_comment_usecase.dart';
import 'package:collectivWork/features/post/domain/usecases/update_comment_usecase.dart';
import 'package:collectivWork/features/post/presentation/Widgets/popup_dialogs/edit_post_dialog.dart';
import 'package:collectivWork/features/post/presentation/Widgets/popup_dialogs/menu_row.dart';
import 'package:collectivWork/features/post/presentation/Widgets/popup_dialogs/report_post_dialog.dart';
import 'package:collectivWork/features/post/presentation/Widgets/popup_dialogs/reported_by_sheet.dart';
import 'package:collectivWork/features/post/presentation/Widgets/comments/post_comments_sheet.dart';
import 'package:collectivWork/features/post/presentation/Widgets/post_media_image_card.dart';
import 'package:collectivWork/features/post/presentation/Widgets/post_network_video_player.dart';
import 'package:collectivWork/features/post/presentation/Widgets/repost_thought_sheet.dart';
import 'package:collectivWork/features/post/presentation/Widgets/post_youtube_player.dart';
import 'package:collectivWork/features/post/presentation/cubit/post_comments_cubit.dart';
import 'package:collectivWork/features/post/presentation/utils/youtube_post_content_resolver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/app_avatar.dart';
import '../constants/reaction_constants.dart';
import '../bloc/post_bloc.dart';
import '../pages/post_image_preview_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PostCard extends StatefulWidget {
  final AnnouncementEntity announcement;
  final int? currentUserId;
  final CreatedByUserEntity? currentUser;
  final bool isReactionProcessing;
  final PostCardAdminActionMode adminActionMode;

  const PostCard({
    super.key,
    required this.announcement,
    this.currentUserId,
    this.currentUser,
    this.isReactionProcessing = false,
    this.adminActionMode = PostCardAdminActionMode.none,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isExpanded = false;
  bool _showReactions = false;
  final Map<int, String> _selectedPollOptions = {};
  static const _cardBorderRadius = 18.0;

  bool get _isActionCard =>
      widget.adminActionMode != PostCardAdminActionMode.none;

  bool get _showReactionProcessingIndicator =>
      widget.isReactionProcessing && !_isActionCard;

  bool _isOwnedRepost(AnnouncementEntity announcement) {
    return widget.currentUserId != null &&
        (announcement.repostedBy == widget.currentUserId ||
            announcement.repostedByUser?.id == widget.currentUserId);
  }

  bool _isOwnedPost(AnnouncementEntity announcement) {
    return widget.currentUserId != null &&
        announcement.createdByUser?.id == widget.currentUserId &&
        announcement.repostedBy == null;
  }

  Future<void> _handleRepostSelection(
    AnnouncementEntity announcement,
    _RepostAction selection,
  ) async {
    if (_showReactions) {
      setState(() => _showReactions = false);
    }

    if (selection == _RepostAction.remove) {
      await _confirmRemoveRepost(announcement);
      return;
    }

    if (selection == _RepostAction.quick) {
      context.read<PostBloc>().add(
        RepostAnnouncementEvent(announcementId: announcement.id),
      );
      return;
    }

    await _showRepostThoughtSheet(announcement);
  }

  Future<void> _showRepostThoughtSheet(AnnouncementEntity announcement) async {
    final thought = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RepostThoughtSheet(),
    );

    if (!mounted || thought == null) return;

    context.read<PostBloc>().add(
      RepostAnnouncementEvent(
        announcementId: announcement.id,
        repostThought: thought,
      ),
    );
  }

  Future<void> _confirmRemoveRepost(AnnouncementEntity announcement) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          alignment: Alignment.center,
          title: Text(
            'Remove repost',
            style: AppTextStyles.heading5(dialogContext),
          ),
          content: Text(
            'This repost will be removed from your feed.',
            style: AppTextStyles.bodySmall(dialogContext),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true || !mounted) return;

    context.read<PostBloc>().add(
      RepostAnnouncementEvent(
        announcementId: announcement.id,
        action: RepostAnnouncementAction.remove,
      ),
    );
  }

  Future<void> _confirmDeleteAnnouncement(
    AnnouncementEntity announcement,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          alignment: Alignment.center,
          title: Text(
            'Delete post',
            style: AppTextStyles.heading5(dialogContext),
          ),
          content: Text(
            'This post will be deleted permanently.',
            style: AppTextStyles.bodySmall(dialogContext),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    context.read<PostBloc>().add(
      DeleteAnnouncementEvent(announcementId: announcement.id),
    );
  }

  Future<void> _showEditPostDialog(AnnouncementEntity announcement) async {
    final result = await showDialog<EditPostDialogResult>(
      context: context,
      builder: (_) => EditPostDialog(announcement: announcement),
    );

    if (result == null || !mounted) return;
    final isRepostEdit = announcement.repostedBy != null;
    final isPollEdit =
        !isRepostEdit && (announcement.type?.trim().toLowerCase() == 'poll');
    final unchanged =
        isRepostEdit
            ? (result.repostThought ?? '').trim() ==
                (announcement.repostThought ?? '').trim()
            : isPollEdit
            ? (result.question ?? '').trim() ==
                    (announcement.question ?? '').trim() &&
                _listEqualsTrimmed(
                  result.options ?? const <String>[],
                  announcement.options ?? const <String>[],
                )
            : result.subject.trim() == announcement.subject.trim() &&
                result.description.trim() == announcement.description.trim();

    if (unchanged) {
      return;
    }

    context.read<PostBloc>().add(
      UpdateAnnouncementEvent(
        announcement: announcement,
        subject: result.subject,
        description: result.description,
        repostThought: result.repostThought,
        options: result.options,
        question: result.question,
      ),
    );
  }

  bool _listEqualsTrimmed(List<String> first, List<String> second) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index].trim() != second[index].trim()) {
        return false;
      }
    }

    return true;
  }

  Future<void> _showReportPostDialog(AnnouncementEntity announcement) async {
    final selectedReason = await showDialog<String>(
      context: context,
      builder: (_) => const ReportPostDialog(),
    );

    if (selectedReason == null || !mounted) return;

    context.read<PostBloc>().add(
      ReportAnnouncementEvent(
        announcementId: announcement.id,
        reason: selectedReason,
        currentUserId: widget.currentUserId,
      ),
    );
  }

  Future<void> _showReportedBySheet(AnnouncementEntity announcement) async {
    await showReportedBySheet(context, reporters: announcement.reportedBy);
  }

  Future<void> _showLikesBottomSheet(AnnouncementEntity announcement) async {
    final likes = announcement.announcementLikes ?? const [];
    if (likes.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final height = MediaQuery.of(sheetContext).size.height;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.zero,
            child: Container(
              constraints: BoxConstraints(maxHeight: height * 0.72),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_cardBorderRadius),
                  topRight: Radius.circular(_cardBorderRadius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSpacing.vSm,
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5DAE1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Liked by',
                            style: AppTextStyles.heading5(
                              sheetContext,
                            ).copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2B2F38),
                            ),
                          ),
                        ),
                        Text(
                          '${likes.length}',
                          style: AppTextStyles.bodySmall(sheetContext).copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE8EDF3),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: likes.length,
                      separatorBuilder:
                          (_, __) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF0F2F5),
                          ),
                      itemBuilder: (context, index) {
                        final like = likes[index];
                        final user = like.user;
                        final reaction = _resolveReaction(like.reactionName);
                        final displayName =
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName
                                : 'Unknown User';

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              AppAvatar(
                                imageUrl: user?.imageUrl,
                                name: displayName,
                                firstName: user?.firstName,
                                lastName: user?.lastName,
                                radius: 22,
                              ),
                              AppSpacing.hMd,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodyMediumHeading(
                                        context,
                                      ).copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2B2F38),
                                      ),
                                    ),
                                    AppSpacing.vXs,
                                    Text(
                                      reaction?.name ?? 'Liked this post',
                                      style: AppTextStyles.bodySmall(
                                        context,
                                      ).copyWith(
                                        fontSize: 12,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (reaction != null) ...[
                                AppSpacing.hSm,
                                SvgPicture.network(
                                  reaction.emoji,
                                  width: 18,
                                  height: 18,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCommentsSheet(AnnouncementEntity announcement) async {
    if (_showReactions) {
      setState(() => _showReactions = false);
    }

    final postRepository = context.read<PostRepository>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      isDismissible: true,

      builder:
          (_) => BlocProvider(
            create:
                (_) => PostCommentsCubit(
                  announcementId: announcement.id,
                  initialComments: announcement.comments ?? const [],
                  addCommentUseCase: AddCommentUseCase(postRepository),
                  reactToCommentUseCase: ReactToCommentUseCase(postRepository),
                  updateCommentUseCase: UpdateCommentUseCase(postRepository),
                  deleteCommentUseCase: DeleteCommentUseCase(postRepository),
                  currentUser: widget.currentUser,
                ),
            child: PostCommentsSheet(
              announcement: announcement,
              onCommentsChanged: (updatedComments) {
                if (!mounted) return;
                context.read<PostBloc>().add(
                  SyncAnnouncementCommentsEvent(
                    announcementId: announcement.id,
                    comments: updatedComments,
                  ),
                );
              },
            ),
          ),
    );
  }

  Reaction? _resolveReaction(String? reactionName) {
    if (reactionName == null || reactionName.trim().isEmpty) {
      return postReactions.firstWhere(
        (reaction) => reaction.name.toLowerCase() == 'like',
        orElse: () => postReactions.first,
      );
    }

    for (final reaction in postReactions) {
      if (reaction.name.toLowerCase() == reactionName.toLowerCase() ||
          reaction.code.toLowerCase() == reactionName.toLowerCase()) {
        return reaction;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final isLarge = screenWidth > 600;
    final cardPadding =
        isCompact
            ? 12.0
            : isLarge
            ? 18.0
            : 14.0;
    final titleFontSize =
        isCompact
            ? 13.5
            : isLarge
            ? 16.5
            : 15.0;
    final bodyFontSize = isCompact ? 13.0 : 14.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: isCompact ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Repost Header (if applicable)
                if (a.repostedBy != null) ...[
                  _buildRepostHeader(a),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: const Color(0xFFE8EDF3)),
                  const SizedBox(height: 10),
                ],

                if (a.repostThought != null) ...[
                  Text(
                    a.repostThought!,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontSize: bodyFontSize,
                      height: 1.55,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                AppSpacing.vMd,
                // Post Header
                _buildPostHeader(a),
                SizedBox(height: isCompact ? 10 : 12),
                // Post Content (Normal or Poll)
                if (a.type == 'poll')
                  _buildPollContent(a)
                else ...[
                  Text(
                    a.subject,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: isCompact ? 6 : 8),
                  _buildDescription(a.description, bodyFontSize),
                ],

                // Badge / Achievement
                if (a.badge != null) ...[
                  SizedBox(height: isCompact ? 10 : 12),
                  _buildAchievementCard(a),
                ],

                // Media Grid
                if (_hasRenderableMedia(a.documentUrls)) ...[
                  SizedBox(height: isCompact ? 10 : 12),
                  _buildMediaAttachments(a.documentUrls ?? const []),
                ],

                // Reactions Summary
                SizedBox(height: isCompact ? 10 : 12),

                _buildReactionsSummary(a),

                const SizedBox(height: 10),
                Divider(height: 1, color: const Color(0xFFE8EDF3)),
                const SizedBox(height: 10),

                // Action Buttons
                _buildActionButtons(a),
              ],
            ),
          ),
          if (_showReactions)
            Positioned(
              bottom: isCompact ? 56 : 60,
              left: cardPadding,
              child: _buildReactionPicker(a),
            ),
        ],
      ),
    );
  }

  Widget _buildRepostHeader(AnnouncementEntity a) {
    final repostedByName = a.repostedByUser?.fullName.trim() ?? '';
    final isBookmarked =
        widget.currentUserId != null &&
        (a.bookmarkedByUserIds?.contains(widget.currentUserId) ?? false);
    final baseStyle = AppTextStyles.bodySmall(
      context,
    ).copyWith(color: const Color(0xFF4B5563), fontWeight: FontWeight.w500);

    return Row(
      children: [
        SvgPicture.asset(AppAssets.alreadyrepostIcon, width: 15, height: 15),
        AppSpacing.hSm,

        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: baseStyle,
              children: [
                if (repostedByName.isNotEmpty)
                  TextSpan(
                    text: repostedByName,
                    style: baseStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2B2F38),
                    ),
                  ),
                TextSpan(
                  text:
                      repostedByName.isNotEmpty
                          ? ' reposted this'
                          : 'Reposted this',
                ),
              ],
            ),
          ),
        ),
        _buildHeaderTrailingMenus(
          announcement: a,
          isBookmarked: isBookmarked,
          showMoreMenu: true,
        ),
      ],
    );
  }

  Widget _buildPostHeader(AnnouncementEntity a) {
    final user = a.createdByUser;
    final praisedUserName = a.praisedUser?.fullName.trim() ?? '';
    final hasPraisedUser = praisedUserName.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final isBookmarked =
        widget.currentUserId != null &&
        (a.bookmarkedByUserIds?.contains(widget.currentUserId) ?? false);
    final dateStr =
        a.repostedBy != null && a.repostPostCreatedAt != null
            ? a.repostPostCreatedAt!
            : a.createdAt;

    String formattedDate = '';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      formattedDate = DateFormat('dd MMM yyyy | hh:mm a').format(dateTime);
    } catch (_) {
      formattedDate = dateStr;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(
          imageUrl: user?.imageUrl,
          name: user?.fullName,
          firstName: user?.firstName,
          lastName: user?.lastName,
          radius: isCompact ? 18 : 20,
        ),
        SizedBox(width: isCompact ? 8 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: user?.fullName ?? 'Unknown User'),
                          if (hasPraisedUser) ...[
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  Icons.emoji_events,
                                  size: 15,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                            TextSpan(text: praisedUserName),
                          ],
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isCompact ? 14 : 15,
                        color: const Color(0xFF2B2F38),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$formattedDate${a.isEdited ? " | Edited" : ""}',
                style: TextStyle(
                  color: const Color(0xFF7A7F89),
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (a.repostedBy == null)
          _buildHeaderTrailingMenus(
            announcement: a,
            isBookmarked: isBookmarked,
            showMoreMenu: true,
          ),
      ],
    );
  }

  Widget _buildHeaderTrailingMenus({
    required AnnouncementEntity announcement,
    required bool isBookmarked,
    required bool showMoreMenu,
  }) {
    final children = <Widget>[];

    switch (widget.adminActionMode) {
      case PostCardAdminActionMode.pendingApproval:
        children.add(_buildPendingApprovalActionMenu(announcement));
        break;
      case PostCardAdminActionMode.reportedPost:
        children.add(_buildReportedPostActionButtons(announcement));
        break;
      case PostCardAdminActionMode.none:
        break;
    }

    final shouldShowMoreMenu =
        showMoreMenu && widget.adminActionMode == PostCardAdminActionMode.none;

    if (shouldShowMoreMenu) {
      if (children.isNotEmpty) {
        children.add(AppSpacing.hXs);
      }
      children.add(_buildMoreMenu(announcement, isBookmarked));
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _buildPendingApprovalActionMenu(AnnouncementEntity announcement) {
    return PopupMenuButton<_AdminReviewAction>(
      enabled: !widget.isReactionProcessing,
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.info_outline_rounded,
        color:
            widget.isReactionProcessing
                ? const Color(0xFF6B7280).withValues(alpha: 0.45)
                : const Color(0xFF6B7280),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      elevation: 6,
      onSelected: (value) {
        context.read<PostBloc>().add(
          MarkAnnouncementAdminRemarkEvent(
            announcementId: announcement.id,
            adminRemark: value.remark,
          ),
        );
      },
      itemBuilder:
          (_) => const [
            PopupMenuItem<_AdminReviewAction>(
              value: _AdminReviewAction.publish,
              child: MenuRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'Publish',
                color: AppColors.successDark,
              ),
            ),
            PopupMenuItem<_AdminReviewAction>(
              value: _AdminReviewAction.reject,
              child: MenuRow(
                icon: Icons.cancel_outlined,
                label: 'Reject',
                color: AppColors.approvalSheetReject,
              ),
            ),
          ],
    );
  }

  Widget _buildReportedPostActionButtons(AnnouncementEntity announcement) {
    final reportedCount =
        announcement.reportedBy.isNotEmpty
            ? announcement.reportedBy.length
            : announcement.reportedByCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<_ReportedPostAdminAction>(
          enabled: !widget.isReactionProcessing,
          padding: EdgeInsets.zero,
          offset: const Offset(0, AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          color: Colors.white,
          elevation: 6,
          onSelected: (value) {
            context.read<PostBloc>().add(
              MarkAnnouncementAdminRemarkEvent(
                announcementId: announcement.id,
                adminRemark: value.remark,
              ),
            );
          },
          itemBuilder:
              (_) => _reportedPostAdminActions(announcement.adminRemark)
                  .map(
                    (action) => PopupMenuItem<_ReportedPostAdminAction>(
                      value: action,
                      child: MenuRow(
                        icon: action.icon,
                        label: action.label,
                        color: action.color,
                      ),
                    ),
                  )
                  .toList(growable: false),
          child: _buildHeaderActionIcon(
            icon: Icons.highlight_off_rounded,
            iconColor: AppColors.warning,
            borderColor: AppColors.warning,
          ),
        ),
        AppSpacing.hSm,
        GestureDetector(
          onTap:
              widget.isReactionProcessing
                  ? null
                  : () => _showReportedBySheet(announcement),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildHeaderActionIcon(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: AppColors.error,
                borderColor: AppColors.error,
              ),
              if (reportedCount > 0)
                Positioned(
                  right: -4,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$reportedCount',
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActionIcon({
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
  }) {
    final resolvedIconColor =
        widget.isReactionProcessing
            ? iconColor.withValues(alpha: 0.45)
            : iconColor;

    final resolvedBorderColor =
        widget.isReactionProcessing
            ? borderColor.withValues(alpha: 0.35)
            : borderColor.withValues(alpha: 0.65);

    return Container(
      width: AppSpacing.iconSmallWidth + AppSpacing.md,
      height: AppSpacing.iconSmallHeight + AppSpacing.md,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: resolvedBorderColor, width: 1.4),
      ),
      child: Icon(icon, size: 18, color: resolvedIconColor),
    );
  }

  List<_ReportedPostAdminAction> _reportedPostAdminActions(
    String? adminRemark,
  ) {
    final normalizedRemark = adminRemark?.trim().toLowerCase() ?? '';

    if (normalizedRemark == 'screened') {
      return const [
        _ReportedPostAdminAction.flagged,
        _ReportedPostAdminAction.approved,
      ];
    }

    if (normalizedRemark == 'approved') {
      return const [
        _ReportedPostAdminAction.flagged,
        _ReportedPostAdminAction.screened,
      ];
    }

    return const [
      _ReportedPostAdminAction.screened,
      _ReportedPostAdminAction.approved,
    ];
  }

  Widget _buildDescription(String description, double bodyFontSize) {
    final youtubeContent = YoutubePostContentResolver.resolve(description);
    if (youtubeContent != null) {
      return _buildYoutubeDescription(
        youtubeContent: youtubeContent,
        bodyFontSize: bodyFontSize,
      );
    }

    return _buildPlainDescription(
      description: description,
      bodyFontSize: bodyFontSize,
    );
  }

  Widget _buildPlainDescription({
    required String description,
    required double bodyFontSize,
  }) {
    final isCompact = MediaQuery.of(context).size.width < 360;
    final int limit = isCompact ? 96 : 132;
    final bool isLong = description.length > limit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isExpanded || !isLong
              ? description
              : '${description.substring(0, limit)}...',
          style: TextStyle(
            fontSize: bodyFontSize,
            height: 1.55,
            color: const Color(0xFF4B5563),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isLong)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Text(
              _isExpanded ? ' Show less' : ' ...more',
              style: const TextStyle(
                color: Color(0xFF8B9098),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildYoutubeDescription({
    required YoutubePostContent youtubeContent,
    required double bodyFontSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (youtubeContent.textWithoutUrl.isNotEmpty) ...[
          _buildPlainDescription(
            description: youtubeContent.textWithoutUrl,
            bodyFontSize: bodyFontSize,
          ),
          AppSpacing.vMd,
        ],
        PostYoutubePlayer(
          url: youtubeContent.url,
          videoId: youtubeContent.videoId,
        ),
      ],
    );
  }

  Widget _buildMediaAttachments(List<MediaItemEntity> items) {
    final validItems = _sanitizeMediaItems(items);
    if (validItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final imageItems = validItems.where(_isImageItem).toList(growable: false);
    final mediaWidgets = <Widget>[];
    var hasRenderedImageGallery = false;

    for (final item in validItems) {
      if (_isImageItem(item)) {
        if (imageItems.length == 1) {
          mediaWidgets.add(
            PostMediaImageCard(
              imageUrl: item.url,
              onTap: () => _openImagePreview(imageItems, 0),
            ),
          );
        } else if (!hasRenderedImageGallery) {
          mediaWidgets.add(_buildImageGallery(imageItems));
          hasRenderedImageGallery = true;
        }
        continue;
      }

      mediaWidgets.add(_buildNonImageMediaItem(item));
    }

    return Column(
      children: [
        for (var index = 0; index < mediaWidgets.length; index++) ...[
          mediaWidgets[index],
          if (index != mediaWidgets.length - 1) AppSpacing.vSm,
        ],
      ],
    );
  }

  Widget _buildImageGallery(List<MediaItemEntity> imageItems) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final visibleItemCount = imageItems.length > 4 ? 4 : imageItems.length;
        final tileWidth = (width - AppSpacing.xs) / 2;
        final tileAspectRatio = width < 360 ? 1.0 : 1.08;

        if (imageItems.length == 2) {
          return Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: tileAspectRatio,
                  child: _buildGalleryTile(imageItems[0], imageItems, 0),
                ),
              ),
              AppSpacing.hXs,
              Expanded(
                child: AspectRatio(
                  aspectRatio: tileAspectRatio,
                  child: _buildGalleryTile(imageItems[1], imageItems, 1),
                ),
              ),
            ],
          );
        }

        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: List.generate(visibleItemCount, (index) {
            final hasMoreItems = index == 3 && imageItems.length > 4;

            return SizedBox(
              width: tileWidth,
              child: AspectRatio(
                aspectRatio: tileAspectRatio,
                child: _buildGalleryTile(
                  imageItems[index],
                  imageItems,
                  index,
                  overlayCount: hasMoreItems ? imageItems.length - 4 : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildGalleryTile(
    MediaItemEntity item,
    List<MediaItemEntity> imageItems,
    int selectedIndex, {
    int? overlayCount,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: Material(
            color: const Color(0xFFF3F4F6),
            child: InkWell(
              onTap: () => _openImagePreview(imageItems, selectedIndex),
              child: PostMediaImageCard(
                imageUrl: item.url,
                maxHeightFactor: 0.38,
              ),
            ),
          ),
        ),
        if (overlayCount != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _openImagePreview(imageItems, selectedIndex),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$overlayCount',
                  style: AppTextStyles.heading3(
                    context,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNonImageMediaItem(MediaItemEntity item) {
    if (_isVideoItem(item) && _hasSupportedMediaUrl(item.url)) {
      return PostNetworkVideoPlayer(url: item.url);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined),
          AppSpacing.hSm,
          Expanded(
            child: Text(
              item.name ?? 'Attachment',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  bool _isImageItem(MediaItemEntity item) {
    final normalizedType = item.type.trim().toLowerCase();
    final normalizedUrl = item.url.toLowerCase();
    return normalizedType.startsWith('image/') ||
        normalizedUrl.endsWith('.png') ||
        normalizedUrl.endsWith('.jpg') ||
        normalizedUrl.endsWith('.jpeg') ||
        normalizedUrl.endsWith('.gif') ||
        normalizedUrl.endsWith('.webp');
  }

  bool _isVideoItem(MediaItemEntity item) {
    final normalizedType = item.type.trim().toLowerCase();
    final normalizedUrl = item.url.toLowerCase();
    return normalizedType.startsWith('video/') ||
        normalizedUrl.endsWith('.mp4') ||
        normalizedUrl.endsWith('.mov') ||
        normalizedUrl.endsWith('.m4v') ||
        normalizedUrl.endsWith('.webm');
  }

  Future<void> _openImagePreview(
    List<MediaItemEntity> images,
    int initialIndex,
  ) async {
    if (images.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => PostImagePreviewPage(
              images: images,
              initialIndex: initialIndex,
            ),
      ),
    );
  }

  bool _hasRenderableMedia(List<MediaItemEntity>? items) {
    if (items == null || items.isEmpty) {
      return false;
    }

    return _sanitizeMediaItems(items).isNotEmpty;
  }

  List<MediaItemEntity> _sanitizeMediaItems(List<MediaItemEntity> items) {
    return items
        .where((item) {
          final url = item.url.trim();
          return url.isNotEmpty && _hasSupportedMediaUrl(url);
        })
        .toList(growable: false);
  }

  bool _hasSupportedMediaUrl(String url) {
    final normalizedUrl = url.trim();
    final parsedUri = Uri.tryParse(normalizedUrl);
    if (parsedUri == null) {
      return false;
    }

    return parsedUri.hasScheme || normalizedUrl.startsWith('/');
  }

  Widget _buildPollContent(AnnouncementEntity a) {
    final bool hasVoted =
        a.answerResponse?.any((r) => r.userId == widget.currentUserId) ?? false;
    final pollOptions = a.options ?? const <String>[];
    final selectedOption = _selectedPollOptions[a.id];
    final votedOption = a.answerResponse
        ?.where((response) => response.userId == widget.currentUserId)
        .map((response) => response.option)
        .cast<String?>()
        .firstWhere((option) => option != null, orElse: () => null);

    if (hasVoted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderDark),
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.question ?? 'Poll',

              style: AppTextStyles.bodyMediumHeading(context).copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.vLg,
            ...?(a.pollResults?.map((res) {
              final bool isMyVote = votedOption == res.option;
              final voteLabel =
                  res.count == 1 ? '1 Vote' : '${res.count} Votes';

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: AppSpacing.lg,
                          height: AppSpacing.lg,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isMyVote
                                      ? AppColors.successDark
                                      : AppColors.borderDark,
                            ),
                            color:
                                isMyVote
                                    ? AppColors.successDark.withValues(
                                      alpha: 0.12,
                                    )
                                    : Colors.transparent,
                          ),
                          child:
                              isMyVote
                                  ? const Icon(
                                    Icons.circle,
                                    size: AppSpacing.md,
                                    color: AppColors.successDark,
                                  )
                                  : null,
                        ),
                        AppSpacing.hMd,
                        Expanded(
                          child: Text(
                            res.option,
                            style: AppTextStyles.bodyMediumHeading(
                              context,
                            ).copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${res.percentage.round()}%',
                          style: AppTextStyles.labelSmall(context).copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vMd,
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      child: LinearProgressIndicator(
                        value: res.percentage / 100,
                        minHeight: AppSpacing.sm,
                        backgroundColor: AppColors.backgroundMedium,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isMyVote
                              ? AppColors.successDark
                              : AppColors.borderDark.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    AppSpacing.vMd,
                    Text(
                      voteLabel,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            })),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          a.question ?? 'Poll',
          style: AppTextStyles.heading4(
            context,
          ).copyWith(color: AppColors.info, fontWeight: FontWeight.w700),
        ),
        AppSpacing.vLg,
        ...pollOptions.map(
          (opt) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: InkWell(
              onTap:
                  widget.isReactionProcessing
                      ? null
                      : () => setState(() {
                        _selectedPollOptions[a.id] = opt;
                      }),
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: AppSpacing.xl,
                    height: AppSpacing.xl,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            selectedOption == opt
                                ? AppColors.info
                                : AppColors.borderDark,
                      ),
                      color:
                          selectedOption == opt
                              ? AppColors.info.withValues(alpha: 0.12)
                              : Colors.transparent,
                    ),
                    child:
                        selectedOption == opt
                            ? const Icon(
                              Icons.circle,
                              size: AppSpacing.md,
                              color: AppColors.info,
                            )
                            : null,
                  ),
                  AppSpacing.hMd,
                  Expanded(
                    child: Text(
                      opt,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (pollOptions.isNotEmpty) ...[
          AppSpacing.vMd,
          SizedBox(
            height: AppSpacing.section,
            child: ElevatedButton(
              onPressed:
                  widget.isReactionProcessing
                      ? null
                      : () {
                        final currentUserId = widget.currentUserId;
                        final optionToSubmit = _selectedPollOptions[a.id];

                        if (currentUserId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to submit vote right now'),
                            ),
                          );
                          return;
                        }

                        if (optionToSubmit == null || optionToSubmit.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select an option first'),
                            ),
                          );
                          return;
                        }

                        context.read<PostBloc>().add(
                          SubmitPollAnswerEvent(
                            announcementId: a.id,
                            userId: currentUserId,
                            selectedOption: optionToSubmit,
                          ),
                        );
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
              ),
              child:
                  widget.isReactionProcessing
                      ? SizedBox(
                        width: AppSpacing.lg,
                        height: AppSpacing.lg,
                        child: const CircularProgressIndicator(
                          strokeWidth: AppSpacing.xs / 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textWhite,
                          ),
                        ),
                      )
                      : Text(
                        'Vote',
                        style: AppTextStyles.buttonMedium(context),
                      ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAchievementCard(AnnouncementEntity a) {
    final badge = a.badge!;
    final isCompact = MediaQuery.of(context).size.width < 360;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: _parseHexColor(badge.color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _parseHexColor(badge.color).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'CERTIFICATE OF APPRECIATION',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Simple Trophy Icon placeholder (matching RN SVG concept)
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.stars, size: 60, color: _parseHexColor(badge.color)),
              if (badge.icon != null)
                const Positioned(
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              a.praisedUser?.fullName ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            a.description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            'Praised by ${a.createdByUser?.fullName ?? "Someone"} on ${DateFormat('dd MMM yyyy').format(DateTime.parse(a.createdAt))}',
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsSummary(AnnouncementEntity a) {
    final showLikes = a.enableLikes;
    final showComments = a.enableComments;

    if (!showLikes && !showComments) {
      return const SizedBox.shrink();
    }

    final totalReactions = (a.reactionsCount?.values ?? []).fold(
      0,
      (sum, count) => sum + count,
    );
    final hasReactions = showLikes && totalReactions > 0;
    final likes = a.announcementLikes;
    final currentUserReaction = likes
        ?.where((like) => like.likedBy == widget.currentUserId)
        .cast<AnnouncementLikeEntity?>()
        .firstWhere((like) => like != null, orElse: () => null);

    String? firstReactionUser;
    if (likes != null) {
      for (final like in likes) {
        if (widget.currentUserId != null &&
            like.likedBy == widget.currentUserId) {
          continue;
        }

        final user = like.user;
        if (user == null) continue;

        final fullName = '${user.firstName} ${user.lastName}'.trim();
        if (fullName.isNotEmpty) {
          firstReactionUser = fullName;
          break;
        }
      }
    }

    final bool isLikedByCurrentUser = currentUserReaction != null;
    final summaryText = _buildReactionSummaryText(
      totalReactions: totalReactions,
      isLikedByCurrentUser: isLikedByCurrentUser,
      firstReactionUser: firstReactionUser,
    );
    final reactionEntries =
        (a.reactionsCount?.entries.toList() ?? const [])
          ..sort((first, second) => second.value.compareTo(first.value));
    final displayedReactions = reactionEntries.take(3).toList();
    final iconStackWidth =
        displayedReactions.isEmpty
            ? 0.0
            : 16 + ((displayedReactions.length - 1) * 12.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showLikes && hasReactions)
          Expanded(
            // ✅ bounds the left side
            child: GestureDetector(
              onTap: () => _showLikesBottomSheet(a),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: iconStackWidth,
                    height: AppSpacing.iconSmallWidth,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ...displayedReactions.asMap().entries.map((entry) {
                          final reaction = postReactions.firstWhere(
                            (r) =>
                                r.code.toLowerCase() ==
                                    entry.value.key.toLowerCase() ||
                                r.name.toLowerCase() ==
                                    entry.value.key.toLowerCase(),
                            orElse: () => postReactions.first,
                          );
                          return Positioned(
                            left: entry.key * 12.0,
                            top: 0,
                            bottom: 0,
                            child: SvgPicture.network(
                              reaction.emoji,
                              width: 16,
                              height: 16,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  AppSpacing.hSm,
                  Flexible(
                    // ✅ now actually works — parent is bounded
                    child: Text(
                      summaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const Expanded(child: SizedBox()),

        if (showComments)
          Text(
            '${a.totalComments} Comments',
            style: AppTextStyles.bodySmall(context).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
      ],
    );
  }

  String _buildReactionSummaryText({
    required int totalReactions,
    required bool isLikedByCurrentUser,
    required String? firstReactionUser,
  }) {
    if (totalReactions <= 0) {
      return 'Be the first to like';
    }

    if (isLikedByCurrentUser) {
      if (totalReactions == 1) {
        return 'You';
      }

      final othersCount = totalReactions - 1;
      return othersCount == 1
          ? 'You and 1 other'
          : 'You and $othersCount others';
    }

    if (totalReactions == 1 && firstReactionUser != null) {
      return firstReactionUser;
    }

    if (firstReactionUser != null) {
      final othersCount = totalReactions - 1;
      return othersCount == 1
          ? '$firstReactionUser and 1 other'
          : '$firstReactionUser and $othersCount others';
    }

    return totalReactions == 1 ? '1 reaction' : '$totalReactions reactions';
  }

  Widget _buildActionButtons(AnnouncementEntity a) {
    final showLikes = a.enableLikes;
    final showComments = a.enableComments;
    final showRepost = a.enableRepost;

    if (!showLikes && !showComments && !showRepost) {
      return const SizedBox.shrink();
    }

    final isAlreadyReposted = _isOwnedRepost(a);
    final userLike = a.announcementLikes
        ?.cast<AnnouncementLikeEntity>()
        .firstWhere(
          (l) => l.likedBy == widget.currentUserId,
          orElse:
              () => const AnnouncementLikeEntity(likedBy: -1, reactionName: ''),
        );
    final isLiked = userLike != null && userLike.likedBy != -1;
    final selectedReaction =
        isLiked
            ? postReactions.firstWhere(
              (r) =>
                  r.name.toLowerCase() == userLike.reactionName.toLowerCase() ||
                  r.code.toLowerCase() == userLike.reactionName.toLowerCase(),
              orElse: () => postReactions.first,
            )
            : null;

    final actionButtons = <Widget>[
      if (showLikes)
        Expanded(
          child: _buildLikeButton(a, isLiked, selectedReaction, userLike?.id),
        ),
      if (showComments)
        Expanded(
          child: _buildActionButton(
            assetPath: AppAssets.commentIcon,
            label: 'Comment',
            onTap: () => _showCommentsSheet(a),
          ),
        ),
      if (showRepost)
        Expanded(
          child: PopupMenuButton<_RepostAction>(
            enabled: !widget.isReactionProcessing,
            padding: EdgeInsets.zero,
            color: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) => _handleRepostSelection(a, value),
            itemBuilder: (_) {
              if (isAlreadyReposted) {
                return const [
                  PopupMenuItem<_RepostAction>(
                    value: _RepostAction.remove,
                    child: MenuRow(
                      assetPath: AppAssets.alreadyrepostIcon,
                      label: 'Remove repost',
                      color: AppColors.error,
                    ),
                  ),
                ];
              }

              return const [
                PopupMenuItem<_RepostAction>(
                  value: _RepostAction.withThought,
                  child: MenuRow(
                    assetPath: AppAssets.repostIcon,
                    label: 'Repost with your thought',
                  ),
                ),
                PopupMenuItem<_RepostAction>(
                  value: _RepostAction.quick,
                  child: MenuRow(
                    assetPath: AppAssets.repostIcon,
                    label: 'Repost',
                  ),
                ),
              ];
            },
            child: _buildActionButtonContent(
              assetPath:
                  isAlreadyReposted
                      ? AppAssets.alreadyrepostIcon
                      : AppAssets.repostIcon,
              label: 'Repost',
              color:
                  _showReactionProcessingIndicator
                      ? isAlreadyReposted
                          ? AppTheme.primaryColor.withValues(alpha: 0.8)
                          : const Color(0xFF6B7280)
                      : isAlreadyReposted
                      ? AppTheme.primaryColor.withValues(alpha: 0.8)
                      : const Color(0xFF6B7280),
            ),
          ),
        ),
    ];

    return Row(children: actionButtons);
  }

  Widget _buildLikeButton(
    AnnouncementEntity a,
    bool isLiked,
    Reaction? selectedReaction,
    dynamic likeId,
  ) {
    return GestureDetector(
      onTap:
          widget.isReactionProcessing
              ? null
              : () {
                if (_showReactions) {
                  setState(() => _showReactions = false);
                  return;
                }
                if (isLiked) {
                  context.read<PostBloc>().add(
                    RemoveLikeEvent(likeId: likeId, announcementId: a.id),
                  );
                } else {
                  context.read<PostBloc>().add(
                    LikeAnnouncementEvent(id: a.id, reaction: 'Like'),
                  );
                }
              },
      onLongPress:
          widget.isReactionProcessing
              ? null
              : () => setState(() => _showReactions = true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        color: Colors.transparent, // Fixes tap area
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showReactionProcessingIndicator) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 6),
            ] else if (selectedReaction != null)
              SvgPicture.network(selectedReaction.emoji, width: 20, height: 20)
            else
              SvgPicture.asset(AppAssets.unlikeIcon, width: 20, height: 20),
            const SizedBox(height: 6),
            Text(
              selectedReaction?.name ?? 'Like',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    _showReactionProcessingIndicator
                        ? Colors.grey
                        : selectedReaction?.color ?? const Color(0xFF6B7280),
                fontWeight:
                    selectedReaction != null
                        ? FontWeight.w700
                        : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionPicker(AnnouncementEntity a) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 64,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children:
              postReactions.map((reaction) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _showReactions = false);
                    context.read<PostBloc>().add(
                      LikeAnnouncementEvent(id: a.id, reaction: reaction.name),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SvgPicture.network(
                      reaction.emoji,
                      width: 32,
                      height: 32,
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    String? assetPath,
    IconData? icon,
    required String label,
    required VoidCallback? onTap,
    Color color = const Color(0xFF6B7280),
  }) {
    final resolvedColor = onTap == null ? color.withValues(alpha: 0.45) : color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: _buildActionButtonContent(
        assetPath: assetPath,
        icon: icon,
        label: label,
        color: resolvedColor,
      ),
    );
  }

  Widget _buildActionButtonContent({
    String? assetPath,
    IconData? icon,
    required String label,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (assetPath != null)
            SvgPicture.asset(assetPath, width: 20, height: 20)
          else if (icon != null)
            Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu(AnnouncementEntity announcement, bool isBookmarked) {
    final canManagePost =
        _isOwnedPost(announcement) || _isOwnedRepost(announcement);
    final isReportedByCurrentUser =
        widget.currentUserId != null &&
        announcement.reportedByUserIds.contains(widget.currentUserId);

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF6B7280)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      elevation: 6,
      onSelected: (value) async {
        if (value == 'bookmark') {
          context.read<PostBloc>().add(
            BookmarkAnnouncementEvent(
              announcementId: announcement.id,
              currentUserId: widget.currentUserId,
            ),
          );
        } else if (value == 'delete') {
          await _confirmDeleteAnnouncement(announcement);
        } else if (value == 'edit') {
          await _showEditPostDialog(announcement);
        } else if (value == 'report') {
          await _showReportPostDialog(announcement);
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem<String>(
              value: 'bookmark',
              child: MenuRow(
                assetPath: AppAssets.bookmarksIcon,
                label: isBookmarked ? 'Bookmarked' : 'Bookmark',
                color: isBookmarked ? AppTheme.primaryColor : null,
              ),
            ),
            if (!canManagePost)
              PopupMenuItem<String>(
                value: 'report',
                enabled: !isReportedByCurrentUser,
                child: MenuRow(
                  icon: Icons.outlined_flag_rounded,
                  label: isReportedByCurrentUser ? 'Reported' : 'Report Post',
                  color: isReportedByCurrentUser ? AppTheme.primaryColor : null,
                ),
              ),
            if (canManagePost)
              const PopupMenuItem<String>(
                value: 'delete',
                child: MenuRow(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete Post',
                  color: AppColors.error,
                ),
              ),
            if (canManagePost)
              const PopupMenuItem<String>(
                value: 'edit',
                child: MenuRow(icon: Icons.edit_outlined, label: 'Edit Post'),
              ),
          ],
    );
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.amber;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.amber;
    }
  }
}

enum _RepostAction { quick, withThought, remove }

enum PostCardAdminActionMode { none, pendingApproval, reportedPost }

enum _AdminReviewAction {
  publish('Publish'),
  reject('Reject');

  final String remark;

  const _AdminReviewAction(this.remark);
}

enum _ReportedPostAdminAction {
  screened(
    remark: 'Screened',
    label: 'Screened',
    icon: Icons.visibility_outlined,
    color: AppColors.warning,
  ),
  flagged(
    remark: 'Flagged',
    label: 'Flagged',
    icon: Icons.outlined_flag_rounded,
    color: AppColors.error,
  ),
  approved(
    remark: 'Approved',
    label: 'Approved',
    icon: Icons.check_circle_outline_rounded,
    color: AppColors.successDark,
  );

  final String remark;
  final String label;
  final IconData icon;
  final Color color;

  const _ReportedPostAdminAction({
    required this.remark,
    required this.label,
    required this.icon,
    required this.color,
  });
}
