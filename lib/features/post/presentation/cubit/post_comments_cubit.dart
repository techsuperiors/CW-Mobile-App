import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/usecases/add_comment_usecase.dart';
import '../../domain/usecases/delete_comment_usecase.dart';
import '../../domain/usecases/react_to_comment_usecase.dart';
import '../../domain/usecases/update_comment_usecase.dart';

enum CommentMutationType { added, updated, deleted, reacted }

class PostCommentsState extends Equatable {
  final List<CommentEntity> comments;
  final bool isSubmitting;
  final List<Object?> processingCommentIds;
  final String? errorMessage;
  final int commentsChangeVersion;
  final Object? editingCommentId;
  final CommentMutationType? lastMutationType;

  const PostCommentsState({
    required this.comments,
    this.isSubmitting = false,
    this.processingCommentIds = const [],
    this.errorMessage,
    this.commentsChangeVersion = 0,
    this.editingCommentId,
    this.lastMutationType,
  });

  PostCommentsState copyWith({
    List<CommentEntity>? comments,
    bool? isSubmitting,
    List<Object?>? processingCommentIds,
    String? errorMessage,
    int? commentsChangeVersion,
    Object? editingCommentId,
    CommentMutationType? lastMutationType,
    bool clearError = false,
    bool clearEditing = false,
  }) {
    return PostCommentsState(
      comments: comments ?? this.comments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      processingCommentIds: processingCommentIds ?? this.processingCommentIds,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      commentsChangeVersion:
          commentsChangeVersion ?? this.commentsChangeVersion,
      editingCommentId:
          clearEditing ? null : editingCommentId ?? this.editingCommentId,
      lastMutationType: lastMutationType ?? this.lastMutationType,
    );
  }

  bool isProcessingComment(Object? commentId) {
    return processingCommentIds.any((id) => id == commentId);
  }

  @override
  List<Object?> get props => [
    comments,
    isSubmitting,
    processingCommentIds,
    errorMessage,
    commentsChangeVersion,
    editingCommentId,
    lastMutationType,
  ];
}

class PostCommentsCubit extends Cubit<PostCommentsState> {
  final int announcementId;
  final AddCommentUseCase addCommentUseCase;
  final ReactToCommentUseCase reactToCommentUseCase;
  final UpdateCommentUseCase updateCommentUseCase;
  final DeleteCommentUseCase deleteCommentUseCase;
  final CreatedByUserEntity? currentUser;

  PostCommentsCubit({
    required this.announcementId,
    required List<CommentEntity> initialComments,
    required this.addCommentUseCase,
    required this.reactToCommentUseCase,
    required this.updateCommentUseCase,
    required this.deleteCommentUseCase,
    required this.currentUser,
  }) : super(
         PostCommentsState(
           comments: List.unmodifiable(_sortComments(initialComments)),
         ),
       );

  void startEditing(CommentEntity comment) {
    emit(
      state.copyWith(
        editingCommentId: comment.id,
        clearError: true,
      ),
    );
  }

  void cancelEditing() {
    emit(state.copyWith(clearEditing: true, clearError: true));
  }

  Future<void> submitComment(String text) async {
    final trimmedComment = text.trim();
    if (trimmedComment.isEmpty || state.isSubmitting) return;

    final editingComment = _commentById(state.editingCommentId);

    emit(state.copyWith(isSubmitting: true, clearError: true));

    if (editingComment != null) {
      await _updateComment(editingComment, trimmedComment);
      return;
    }

    final result = await addCommentUseCase(
      AddCommentParams(
        announcementId: announcementId,
        comment: trimmedComment,
      ),
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
          ),
        );
      },
      (comment) {
        final hydratedComment = CommentEntity(
          id: comment.id,
          comment: comment.comment,
          userId: comment.userId ?? currentUser?.id,
          isEdited: comment.isEdited,
          createdAt: comment.createdAt,
          commentLikes: comment.commentLikes,
          reactionsCount: comment.reactionsCount,
          user: comment.user ?? currentUser,
          updatedAt: comment.updatedAt,
        );

        emit(
          state.copyWith(
            comments: List.unmodifiable(
              _sortComments([...state.comments, hydratedComment]),
            ),
            isSubmitting: false,
            commentsChangeVersion: state.commentsChangeVersion + 1,
            clearEditing: true,
            clearError: true,
            lastMutationType: CommentMutationType.added,
          ),
        );
      },
    );
  }

  Future<void> reactToComment(CommentEntity comment, String reaction) async {
    if (currentUser == null || state.isProcessingComment(comment.id)) return;

    final normalizedReaction = reaction.trim();

    emit(
      state.copyWith(
        processingCommentIds: [...state.processingCommentIds, comment.id],
        clearError: true,
      ),
    );

    final result = await reactToCommentUseCase(
      ReactToCommentParams(
        announcementId: announcementId,
        commentId: _asInt(comment.id),
        reaction: normalizedReaction,
      ),
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            processingCommentIds: _removeProcessingId(comment.id),
            errorMessage: failure.message,
          ),
        );
      },
      (success) {
        if (!success) {
          emit(
            state.copyWith(
              processingCommentIds: _removeProcessingId(comment.id),
              errorMessage: 'Unable to update comment reaction right now',
            ),
          );
          return;
        }

        final updatedComment = _applyReactionChange(
          comment,
          normalizedReaction,
        );

        emit(
          state.copyWith(
            comments: List.unmodifiable(
              state.comments
                  .map((item) => item.id == comment.id ? updatedComment : item)
                  .toList(),
            ),
            processingCommentIds: _removeProcessingId(comment.id),
            commentsChangeVersion: state.commentsChangeVersion + 1,
            clearError: true,
            lastMutationType: CommentMutationType.reacted,
          ),
        );
      },
    );
  }

  Future<void> deleteComment(CommentEntity comment) async {
    if (state.isProcessingComment(comment.id)) return;

    emit(
      state.copyWith(
        processingCommentIds: [...state.processingCommentIds, comment.id],
        clearError: true,
      ),
    );

    final result = await deleteCommentUseCase(
      DeleteCommentParams(commentId: _asInt(comment.id)),
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            processingCommentIds: _removeProcessingId(comment.id),
            errorMessage: failure.message,
          ),
        );
      },
      (success) {
        if (!success) {
          emit(
            state.copyWith(
              processingCommentIds: _removeProcessingId(comment.id),
              errorMessage: 'Unable to delete comment right now',
            ),
          );
          return;
        }

        emit(
          state.copyWith(
            comments: List.unmodifiable(
              state.comments.where((item) => item.id != comment.id).toList(),
            ),
            processingCommentIds: _removeProcessingId(comment.id),
            commentsChangeVersion: state.commentsChangeVersion + 1,
            clearEditing: state.editingCommentId == comment.id,
            clearError: true,
            lastMutationType: CommentMutationType.deleted,
          ),
        );
      },
    );
  }

  Future<void> _updateComment(CommentEntity comment, String text) async {
    final result = await updateCommentUseCase(
      UpdateCommentParams(
        commentId: _asInt(comment.id),
        comment: text,
        isEdited: true,
      ),
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
          ),
        );
      },
      (success) {
        if (!success) {
          emit(
            state.copyWith(
              isSubmitting: false,
              errorMessage: 'Unable to update comment right now',
            ),
          );
          return;
        }

        final updatedComment = comment.copyWith(
          comment: text,
          isEdited: true,
          updatedAt: DateTime.now().toIso8601String(),
        );

        emit(
          state.copyWith(
            comments: List.unmodifiable(
              _sortComments(
                state.comments
                    .map((item) => item.id == comment.id ? updatedComment : item)
                    .toList(),
              ),
            ),
            isSubmitting: false,
            commentsChangeVersion: state.commentsChangeVersion + 1,
            clearEditing: true,
            clearError: true,
            lastMutationType: CommentMutationType.updated,
          ),
        );
      },
    );
  }

  CommentEntity? _commentById(Object? id) {
    if (id == null) return null;

    for (final comment in state.comments) {
      if (comment.id == id) return comment;
    }
    return null;
  }

  CommentEntity _applyReactionChange(
    CommentEntity comment,
    String reaction,
  ) {
    final normalizedReaction = reaction.trim();
    final currentLikes = List<CommentLikeEntity>.from(
      comment.commentLikes ?? const [],
    );
    final currentCounts = Map<String, int>.from(
      comment.reactionsCount ?? const {},
    );
    final currentUserId = currentUser?.id;

    if (currentUserId == null) return comment;

    final existingIndex = currentLikes.indexWhere(
      (like) => like.likedBy == currentUserId,
    );
    final existingReaction =
        existingIndex >= 0 ? currentLikes[existingIndex].reactions : null;

    if (existingReaction != null && existingReaction.isNotEmpty) {
      _decrementReactionCount(currentCounts, existingReaction);
    }

    if (normalizedReaction.isNotEmpty) {
      final updatedLike = CommentLikeEntity(
        id: existingIndex >= 0 ? currentLikes[existingIndex].id : null,
        likedBy: currentUserId,
        reactions: normalizedReaction,
      );

      if (existingIndex >= 0) {
        currentLikes[existingIndex] = updatedLike;
      } else {
        currentLikes.add(updatedLike);
      }
      _incrementReactionCount(currentCounts, normalizedReaction);
    } else if (existingIndex >= 0) {
      currentLikes.removeAt(existingIndex);
    }

    return comment.copyWith(
      commentLikes: List.unmodifiable(currentLikes),
      reactionsCount: Map.unmodifiable(currentCounts),
    );
  }

  List<Object?> _removeProcessingId(Object? id) {
    return state.processingCommentIds.where((item) => item != id).toList();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static void _incrementReactionCount(
    Map<String, int> counts,
    String reaction,
  ) {
    counts[reaction] = (counts[reaction] ?? 0) + 1;
  }

  static void _decrementReactionCount(
    Map<String, int> counts,
    String reaction,
  ) {
    final nextCount = (counts[reaction] ?? 0) - 1;
    if (nextCount <= 0) {
      counts.remove(reaction);
      return;
    }
    counts[reaction] = nextCount;
  }

  static List<CommentEntity> _sortComments(List<CommentEntity> comments) {
    final sortedComments = List<CommentEntity>.from(comments);
    sortedComments.sort((first, second) {
      final secondDate = _parseCommentDate(second);
      final firstDate = _parseCommentDate(first);
      return secondDate.compareTo(firstDate);
    });
    return sortedComments;
  }

  static DateTime _parseCommentDate(CommentEntity comment) {
    final rawDate = comment.updatedAt ?? comment.createdAt;
    if (rawDate == null || rawDate.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.tryParse(rawDate)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
