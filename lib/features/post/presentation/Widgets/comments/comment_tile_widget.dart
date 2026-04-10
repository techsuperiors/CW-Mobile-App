import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/utils/app_spacing.dart';
import '../../../../../core/widgets/common/app_avatar.dart';
import '../../../domain/entities/announcement_entity.dart';
import '../../constants/reaction_constants.dart';

class CommentTile extends StatefulWidget {
  final CommentEntity comment;
  final int? currentUserId;
  final String relativeTime;
  final bool isProcessing;
  final VoidCallback onReactTap;
  final ValueChanged<String> onReactionSelected;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const CommentTile({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.relativeTime,
    required this.isProcessing,
    required this.onReactTap,
    required this.onReactionSelected,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _showReactions = false;

  @override
  void didUpdateWidget(covariant CommentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_showReactions && oldWidget.comment.id != widget.comment.id) {
      _showReactions = false;
    }
  }

  bool get _isOwner {
    if (widget.currentUserId == null) return false;
    return widget.comment.userId == widget.currentUserId ||
        widget.comment.user?.id == widget.currentUserId;
  }

  Widget _buildReactionPicker() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 96,
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
                    widget.onReactionSelected(reaction.name);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Tooltip(
                      message: reaction.name,
                      child: SvgPicture.network(
                        reaction.emoji,
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.comment.user;
    final displayName =
        user?.fullName.trim().isNotEmpty == true
            ? user!.fullName.trim()
            : 'User';
    final currentReaction = findCurrentUserReaction(
      widget.comment,
      widget.currentUserId,
    );
    final reaction = _resolveReaction(currentReaction?.reactions);
    final sortedReactions = _reactionEntries(widget.comment.reactionsCount);
    final totalReactions = sortedReactions.fold<int>(
      0,
      (sum, entry) => sum + entry.value,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(
          imageUrl: user?.imageUrl,
          name: displayName,
          firstName: user?.firstName,
          lastName: user?.lastName,
          radius: 20,
        ),
        AppSpacing.hMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (widget.comment.isEdited) ...[
                          AppSpacing.vXs,
                          Text(
                            'Edited',
                            style: AppTextStyles.bodySmall(
                              context,
                            ).copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                        AppSpacing.vSm,
                        Text(
                          widget.comment.comment,
                          style: AppTextStyles.bodyMediumHeading(
                            context,
                          ).copyWith(
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (widget.relativeTime.isNotEmpty)
                        Text(
                          widget.relativeTime,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (_isOwner)
                        PopupMenuButton<_CommentMenuAction>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Color(0xFF667085),
                          ),
                          onSelected: (value) {
                            if (value == _CommentMenuAction.edit) {
                              widget.onEditTap();
                            } else {
                              widget.onDeleteTap();
                            }
                          },
                          itemBuilder:
                              (_) => const [
                                PopupMenuItem<_CommentMenuAction>(
                                  value: _CommentMenuAction.edit,
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem<_CommentMenuAction>(
                                  value: _CommentMenuAction.delete,
                                  child: Text('Delete'),
                                ),
                              ],
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.xs),
                          child: Icon(
                            Icons.more_horiz,
                            color: Color(0xFF98A2B3),
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // AppSpacing.vSm,
              AppSpacing.vSm,
              Row(
                children: [
                  GestureDetector(
                    onTap:
                        widget.isProcessing
                            ? null
                            : () {
                              if (_showReactions) {
                                setState(() => _showReactions = false);
                                return;
                              }
                              widget.onReactTap();
                            },
                    onLongPress:
                        widget.isProcessing
                            ? null
                            : () => setState(
                              () => _showReactions = !_showReactions,
                            ),
                    child: Text(
                      widget.isProcessing
                          ? 'Updating...'
                          : (reaction?.name ?? 'Like'),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color:
                            widget.isProcessing
                                ? const Color(0xFF98A2B3)
                                : reaction?.color ?? const Color(0xFF667085),
                        fontWeight:
                            reaction != null
                                ? FontWeight.w700
                                : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (totalReactions > 0) ...[
                    AppSpacing.hSm,
                    SizedBox(
                      width: sortedReactions.length > 1 ? 30 : 16,
                      height: 16,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children:
                            sortedReactions
                                .take(3)
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                                  final resolvedReaction = _resolveReaction(
                                    entry.value.key,
                                  );
                                  if (resolvedReaction == null) {
                                    return const SizedBox.shrink();
                                  }

                                  return Positioned(
                                    left: entry.key * 10.0,
                                    child: SvgPicture.network(
                                      resolvedReaction.emoji,
                                      width: 16,
                                      height: 16,
                                    ),
                                  );
                                })
                                .toList(),
                      ),
                    ),
                    AppSpacing.hXs,
                    Text(
                      '$totalReactions',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              if (_showReactions) ...[
                AppSpacing.vSm,
                _buildReactionPicker(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

enum _CommentMenuAction { edit, delete }

CommentLikeEntity? findCurrentUserReaction(
  CommentEntity comment,
  int? currentUserId,
) {
  if (currentUserId == null) return null;

  final likes = comment.commentLikes ?? const [];
  for (final like in likes) {
    if (like.likedBy == currentUserId && like.reactions.trim().isNotEmpty) {
      return like;
    }
  }
  return null;
}

Reaction? _resolveReaction(String? reactionName) {
  if (reactionName == null || reactionName.trim().isEmpty) {
    return null;
  }

  for (final reaction in postReactions) {
    if (reaction.name.toLowerCase() == reactionName.toLowerCase() ||
        reaction.code.toLowerCase() == reactionName.toLowerCase()) {
      return reaction;
    }
  }

  return null;
}

List<MapEntry<String, int>> _reactionEntries(Map<String, int>? reactionsCount) {
  if (reactionsCount == null || reactionsCount.isEmpty) return const [];

  final entries = reactionsCount.entries.toList();
  entries.sort((first, second) => second.value.compareTo(first.value));
  return entries;
}
