import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:collectivWork/core/constants/app_colors.dart';
import 'package:collectivWork/core/constants/app_text_styles.dart';
import 'package:collectivWork/core/theme/app_theme.dart';
import 'package:collectivWork/core/utils/app_spacing.dart';
import 'package:collectivWork/core/widgets/common/app_avatar.dart';
import 'package:collectivWork/features/post/domain/entities/announcement_entity.dart';
import 'package:collectivWork/features/post/presentation/cubit/post_comments_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'comment_tile_widget.dart';

const List<String> _quickCommentEmojis = <String>[
  '👍',
  '❤️',
  '😂',
  '👏',
  '🔥',
  '🎉',
  '😊',
  '😍',
];

class PostCommentsSheet extends StatefulWidget {
  final AnnouncementEntity announcement;
  final ValueChanged<List<CommentEntity>>? onCommentsChanged;

  const PostCommentsSheet({
    super.key,
    required this.announcement,
    this.onCommentsChanged,
  });

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _commentFocusNode.addListener(_handleCommentFocusChange);
  }

  @override
  void dispose() {
    _commentFocusNode.removeListener(_handleCommentFocusChange);
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _handleCommentFocusChange() {
    if (_commentFocusNode.hasFocus && _showEmojiPicker && mounted) {
      setState(() {
        _showEmojiPicker = false;
      });
    }
  }

  String get _postPreviewText {
    final subject = widget.announcement.subject.trim();
    final description = widget.announcement.description.trim();

    if (description.isEmpty) return subject;
    if (subject.isEmpty) return description;
    return '$subject\n$description';
  }

  String _formatRelativeTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';

    try {
      final date = DateTime.parse(rawDate).toLocal();
      final difference = DateTime.now().difference(date);

      if (difference.inSeconds < 60) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m';
      if (difference.inHours < 24) return '${difference.inHours}h';
      if (difference.inDays < 7) return '${difference.inDays}d';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  void _startEditing(CommentEntity comment) {
    _commentController.text = comment.comment;
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    context.read<PostCommentsCubit>().startEditing(comment);
    _commentFocusNode.requestFocus();
    setState(() {});
  }

  Future<void> _confirmDeleteComment(CommentEntity comment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            alignment: Alignment.center,
            title: Text(
              'Delete comment',
              style: AppTextStyles.heading5(dialogContext),
            ),
            content: Text(
              'This comment will be removed permanently.',
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
          ),
    );

    if (shouldDelete != true || !mounted) return;
    if (context.read<PostCommentsCubit>().state.editingCommentId ==
        comment.id) {
      _commentController.clear();
      _commentFocusNode.unfocus();
    }
    await context.read<PostCommentsCubit>().deleteComment(comment);
  }

  void _handleCancel(PostCommentsState state) {
    if (state.editingCommentId != null) {
      _commentController.clear();
      _commentFocusNode.unfocus();
      _showEmojiPicker = false;
      context.read<PostCommentsCubit>().cancelEditing();
      setState(() {});
      return;
    }

    Navigator.of(context).pop();
  }

  void _toggleEmojiPicker() {
    if (!_commentController.selection.isValid) {
      _commentController.selection = TextSelection.collapsed(
        offset: _commentController.text.length,
      );
    }

    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });

    if (_showEmojiPicker) {
      _commentFocusNode.unfocus();
    } else {
      _commentFocusNode.requestFocus();
    }
  }

  void _focusCommentField() {
    if (_showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
    }
    _commentFocusNode.requestFocus();
  }

  void _insertEmoji(String emoji) {
    final text = _commentController.text;
    final selection = _commentController.selection;
    final hasValidSelection =
        selection.isValid &&
        selection.start >= 0 &&
        selection.end >= selection.start &&
        selection.end <= text.length;

    final start = hasValidSelection ? selection.start : text.length;
    final end = hasValidSelection ? selection.end : text.length;
    final updatedText = text.replaceRange(start, end, emoji);
    final cursorOffset = start + emoji.length;

    _commentController.value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostCommentsCubit, PostCommentsState>(
      listenWhen:
          (previous, current) =>
              previous.commentsChangeVersion != current.commentsChangeVersion ||
              previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }

        if (state.lastMutationType == CommentMutationType.added ||
            state.lastMutationType == CommentMutationType.updated) {
          _commentController.clear();
          _showEmojiPicker = false;
          if (state.lastMutationType == CommentMutationType.added) {
            _commentFocusNode.requestFocus();
          } else {
            _commentFocusNode.unfocus();
          }
        }

        if (state.lastMutationType != null &&
            (state.errorMessage == null || state.errorMessage!.isEmpty)) {
          widget.onCommentsChanged?.call(List.unmodifiable(state.comments));
        }
        if (mounted) {
          setState(() {});
        }
      },
      builder: (context, state) {
        final comments = state.comments;
        final isEditing = state.editingCommentId != null;
        final canSubmit =
            _commentController.text.trim().isNotEmpty && !state.isSubmitting;
        final currentUserId = context.read<PostCommentsCubit>().currentUser?.id;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSpacing.vSm,
                    if (comments.isNotEmpty)
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  AppSpacing.xs,
                                  AppSpacing.lg,
                                  AppSpacing.md,
                                ),
                                itemCount: comments.length,
                                separatorBuilder: (_, __) => AppSpacing.vLg,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  return CommentTile(
                                    comment: comment,
                                    currentUserId: currentUserId,
                                    relativeTime: _formatRelativeTime(
                                      comment.updatedAt ?? comment.createdAt,
                                    ),
                                    isProcessing: state.isProcessingComment(
                                      comment.id,
                                    ),
                                    onReactTap: () {
                                      final currentReaction =
                                          findCurrentUserReaction(
                                            comment,
                                            currentUserId,
                                          );
                                      context
                                          .read<PostCommentsCubit>()
                                          .reactToComment(
                                            comment,
                                            currentReaction == null
                                                ? 'Like'
                                                : '',
                                          );
                                    },
                                    onReactionSelected:
                                        (selectedReaction) => context
                                            .read<PostCommentsCubit>()
                                            .reactToComment(
                                              comment,
                                              selectedReaction,
                                            ),
                                    onEditTap: () => _startEditing(comment),
                                    onDeleteTap:
                                        () => _confirmDeleteComment(comment),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Align(
                          alignment: Alignment.topLeft,
                          child: _buildHeader()),

                    const Divider(height: 1, color: Color(0xFFE8EDF3)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          if (isEditing)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Editing comment',
                                      style: AppTextStyles.labelSmall(
                                        context,
                                      ).copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _CommentComposer(
                            controller: _commentController,
                            focusNode: _commentFocusNode,
                            isSubmitting: state.isSubmitting,
                            isEmojiPickerVisible: _showEmojiPicker,
                            onEmojiTap: _toggleEmojiPicker,
                            onFieldTap: _focusCommentField,
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_showEmojiPicker) ...[
                            AppSpacing.vMd,
                            _QuickCommentEmojiPicker(
                              emojis: _quickCommentEmojis,
                              isSubmitting: state.isSubmitting,
                              onEmojiSelected: _insertEmoji,
                            ),
                          ],

                          AppSpacing.vLg,
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  canSubmit
                                      ? () => context
                                          .read<PostCommentsCubit>()
                                          .submitComment(
                                            _commentController.text,
                                          )
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.attendanceTeal,
                                foregroundColor: AppColors.textWhite,
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                disabledBackgroundColor:
                                    AppColors.attendanceTeal,
                              ),

                              child:
                                  state.isSubmitting
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        isEditing
                                            ? 'Update Comment'
                                            : 'Comment',
                                        style: AppTextStyles.buttonLarge(
                                          context,
                                        ),
                                      ),
                            ),
                          ),
                          AppSpacing.vMd,
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _handleCancel(state),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFD9DEE7),
                                ),
                                foregroundColor: AppColors.textPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                isEditing ? 'Cancel Edit' : 'Cancel',
                                style: AppTextStyles.buttonLarge(
                                  context,
                                ).copyWith(color: AppColors.textPrimary),
                              ),
                            ),
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
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.iconMediumWidth,
            height: AppSpacing.iconMediumHeight,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
            ),
            child: Center(
              child: SvgPicture.asset(
                AppAssets.commentIcon,
                width: 24,
                height: 24,
              ),
            ),
          ),
          AppSpacing.vLg,
          Text(
            'Comments',
            style: AppTextStyles.heading3(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (_postPreviewText.isNotEmpty) ...[
            AppSpacing.vMd,
            Text(
              _postPreviewText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textSecondary, height: 1.2),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickCommentEmojiPicker extends StatelessWidget {
  final List<String> emojis;
  final bool isSubmitting;
  final ValueChanged<String> onEmojiSelected;

  const _QuickCommentEmojiPicker({
    required this.emojis,
    required this.isSubmitting,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - (AppSpacing.section + AppSpacing.xl),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: AppSpacing.md,
              offset: const Offset(0, AppSpacing.xs),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children:
                emojis.map((emoji) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: InkWell(
                      onTap: isSubmitting ? null : () => onEmojiSelected(emoji),
                      borderRadius: BorderRadius.circular(AppSpacing.xl),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Text(
                          emoji,
                          style: AppTextStyles.heading4(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final bool isEmojiPickerVisible;
  final VoidCallback onEmojiTap;
  final VoidCallback onFieldTap;
  final ValueChanged<String> onChanged;

  const _CommentComposer({
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.isEmojiPickerVisible,
    required this.onEmojiTap,
    required this.onFieldTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<PostCommentsCubit>().currentUser;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppAvatar(
          imageUrl: currentUser?.imageUrl,
          name: currentUser?.fullName,
          firstName: currentUser?.firstName,
          lastName: currentUser?.lastName,
          radius: 20,
        ),
        AppSpacing.hMd,
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: !isSubmitting,
            minLines: 1,
            maxLines: 4,
            onTap: onFieldTap,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: const Color(0xFF98A2B3)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: IconButton(
                tooltip: 'Add emoji',
                onPressed: isSubmitting ? null : onEmojiTap,
                icon: Icon(
                  Icons.sentiment_satisfied_alt_outlined,
                  size: 21,
                  color:
                      isEmojiPickerVisible
                          ? AppTheme.primaryColor
                          : const Color(0xFF667085),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: Color(0xFFD9DEE7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: Color(0xFFD9DEE7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
