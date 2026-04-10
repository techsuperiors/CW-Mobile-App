import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/entities/post_feed_result_entity.dart';
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

// Events
abstract class PostEvent extends Equatable {
  const PostEvent();

  @override
  List<Object?> get props => [];
}

class FetchPostsEvent extends PostEvent {
  final String postName;
  final String searchParam;
  final bool showLoader;
  final bool onlyRepostedByCurrentUser;
  final int? repostedByUserId;

  const FetchPostsEvent({
    this.postName = 'all',
    this.searchParam = '',
    this.showLoader = true,
    this.onlyRepostedByCurrentUser = false,
    this.repostedByUserId,
  });

  @override
  List<Object?> get props => [
    postName,
    searchParam,
    showLoader,
    onlyRepostedByCurrentUser,
    repostedByUserId,
  ];
}

class FetchAnnouncementDetailsEvent extends PostEvent {
  final int announcementId;
  final bool showLoader;

  const FetchAnnouncementDetailsEvent({
    required this.announcementId,
    this.showLoader = true,
  });

  @override
  List<Object?> get props => [announcementId, showLoader];
}

class RefreshPostsEvent extends PostEvent {
  final bool showLoader;

  const RefreshPostsEvent({this.showLoader = false});

  @override
  List<Object?> get props => [showLoader];
}

class LikeAnnouncementEvent extends PostEvent {
  final int id;
  final String reaction;

  const LikeAnnouncementEvent({required this.id, required this.reaction});

  @override
  List<Object?> get props => [id, reaction];
}

class RemoveLikeEvent extends PostEvent {
  final int likeId;
  final int announcementId;

  const RemoveLikeEvent({required this.likeId, required this.announcementId});

  @override
  List<Object?> get props => [likeId, announcementId];
}

class BookmarkAnnouncementEvent extends PostEvent {
  final int announcementId;
  final int? currentUserId;

  const BookmarkAnnouncementEvent({
    required this.announcementId,
    this.currentUserId,
  });

  @override
  List<Object?> get props => [announcementId, currentUserId];
}

class DeleteAnnouncementEvent extends PostEvent {
  final int announcementId;

  const DeleteAnnouncementEvent({required this.announcementId});

  @override
  List<Object?> get props => [announcementId];
}

class UpdateAnnouncementEvent extends PostEvent {
  final AnnouncementEntity announcement;
  final String subject;
  final String description;
  final String? repostThought;
  final List<String>? options;
  final String? question;

  const UpdateAnnouncementEvent({
    required this.announcement,
    required this.subject,
    required this.description,
    this.repostThought,
    this.options,
    this.question,
  });

  @override
  List<Object?> get props => [
    announcement,
    subject,
    description,
    repostThought,
    options,
    question,
  ];
}

class ReportAnnouncementEvent extends PostEvent {
  final int announcementId;
  final String reason;
  final int? currentUserId;

  const ReportAnnouncementEvent({
    required this.announcementId,
    required this.reason,
    this.currentUserId,
  });

  @override
  List<Object?> get props => [announcementId, reason, currentUserId];
}

class MarkAnnouncementAdminRemarkEvent extends PostEvent {
  final int announcementId;
  final String adminRemark;

  const MarkAnnouncementAdminRemarkEvent({
    required this.announcementId,
    required this.adminRemark,
  });

  @override
  List<Object?> get props => [announcementId, adminRemark];
}

class RepostAnnouncementEvent extends PostEvent {
  final int announcementId;
  final String? repostThought;
  final RepostAnnouncementAction action;

  const RepostAnnouncementEvent({
    required this.announcementId,
    this.repostThought,
    this.action = RepostAnnouncementAction.create,
  });

  @override
  List<Object?> get props => [announcementId, repostThought, action];
}

enum RepostAnnouncementAction { create, remove }

class SyncAnnouncementCommentsEvent extends PostEvent {
  final int announcementId;
  final List<CommentEntity> comments;

  const SyncAnnouncementCommentsEvent({
    required this.announcementId,
    required this.comments,
  });

  @override
  List<Object?> get props => [announcementId, comments];
}

class SubmitPollAnswerEvent extends PostEvent {
  final int announcementId;
  final int userId;
  final String selectedOption;

  const SubmitPollAnswerEvent({
    required this.announcementId,
    required this.userId,
    required this.selectedOption,
  });

  @override
  List<Object?> get props => [announcementId, userId, selectedOption];
}

// States
abstract class PostState extends Equatable {
  const PostState();

  @override
  List<Object?> get props => [];
}

class PostInitial extends PostState {}

class PostLoading extends PostState {}

class PostLoaded extends PostState {
  final List<AnnouncementEntity> announcements;
  final List<int> processingPostIds;
  final String? actionMessage;
  final String? actionErrorMessage;
  final String currentPostName;
  final String currentSearchParam;
  final int? currentAnnouncementId;
  final int allPostsCount;
  final int myPostsCount;
  final int praisePostsCount;
  final bool onlyRepostedByCurrentUser;
  final int? repostedByUserId;

  const PostLoaded(
    this.announcements, {
    this.processingPostIds = const [],
    this.actionMessage,
    this.actionErrorMessage,
    this.currentPostName = 'all',
    this.currentSearchParam = '',
    this.currentAnnouncementId,
    this.allPostsCount = 0,
    this.myPostsCount = 0,
    this.praisePostsCount = 0,
    this.onlyRepostedByCurrentUser = false,
    this.repostedByUserId,
  });

  PostLoaded copyWith({
    List<AnnouncementEntity>? announcements,
    List<int>? processingPostIds,
    String? actionMessage,
    String? actionErrorMessage,
    String? currentPostName,
    String? currentSearchParam,
    int? currentAnnouncementId,
    int? allPostsCount,
    int? myPostsCount,
    int? praisePostsCount,
    bool? onlyRepostedByCurrentUser,
    int? repostedByUserId,
    bool clearActionFeedback = false,
  }) {
    return PostLoaded(
      announcements ?? this.announcements,
      processingPostIds: processingPostIds ?? this.processingPostIds,
      actionMessage:
          clearActionFeedback ? null : actionMessage ?? this.actionMessage,
      actionErrorMessage:
          clearActionFeedback
              ? null
              : actionErrorMessage ?? this.actionErrorMessage,
      currentPostName: currentPostName ?? this.currentPostName,
      currentSearchParam: currentSearchParam ?? this.currentSearchParam,
      currentAnnouncementId:
          currentAnnouncementId ?? this.currentAnnouncementId,
      allPostsCount: allPostsCount ?? this.allPostsCount,
      myPostsCount: myPostsCount ?? this.myPostsCount,
      praisePostsCount: praisePostsCount ?? this.praisePostsCount,
      onlyRepostedByCurrentUser:
          onlyRepostedByCurrentUser ?? this.onlyRepostedByCurrentUser,
      repostedByUserId: repostedByUserId ?? this.repostedByUserId,
    );
  }

  @override
  List<Object?> get props => [
    announcements,
    processingPostIds,
    actionMessage,
    actionErrorMessage,
    currentPostName,
    currentSearchParam,
    currentAnnouncementId,
    allPostsCount,
    myPostsCount,
    praisePostsCount,
    onlyRepostedByCurrentUser,
    repostedByUserId,
  ];
}

class PostError extends PostState {
  final String message;

  const PostError(this.message);

  @override
  List<Object?> get props => [message];
}

class _CachedPostFeed {
  final List<AnnouncementEntity> announcements;
  final int allPostsCount;
  final int myPostsCount;
  final int praisePostsCount;

  const _CachedPostFeed({
    required this.announcements,
    required this.allPostsCount,
    required this.myPostsCount,
    required this.praisePostsCount,
  });

  factory _CachedPostFeed.fromResult(PostFeedResultEntity result) {
    return _CachedPostFeed(
      announcements: result.announcements,
      allPostsCount: result.allPostsCount,
      myPostsCount: result.myPostsCount,
      praisePostsCount: result.praisePostsCount,
    );
  }
}

class _FeedOverviewCounts {
  final int allPostsCount;
  final int myPostsCount;
  final int praisePostsCount;

  const _FeedOverviewCounts({
    required this.allPostsCount,
    required this.myPostsCount,
    required this.praisePostsCount,
  });

  bool get isZero =>
      allPostsCount == 0 && myPostsCount == 0 && praisePostsCount == 0;
}

// Bloc
class PostBloc extends Bloc<PostEvent, PostState> {
  final GetAnnouncementsUseCase getAnnouncementsUseCase;
  final GetAnnouncementDetailsUseCase getAnnouncementDetailsUseCase;
  final BookmarkAnnouncementUseCase bookmarkAnnouncementUseCase;
  final RemoveBookmarkUseCase removeBookmarkUseCase;
  final LikeAnnouncementUseCase likeAnnouncementUseCase;
  final MarkAnnouncementAdminRemarkUseCase markAnnouncementAdminRemarkUseCase;
  final ReportAnnouncementUseCase reportAnnouncementUseCase;
  final RemoveLikeUseCase removeLikeUseCase;
  final SubmitPollAnswerUseCase submitPollAnswerUseCase;
  final RepostAnnouncementUseCase repostAnnouncementUseCase;
  final RemoveRepostUseCase removeRepostUseCase;
  final DeleteAnnouncementUseCase deleteAnnouncementUseCase;
  final UpdateAnnouncementUseCase updateAnnouncementUseCase;

  PostBloc({
    required this.getAnnouncementsUseCase,
    required this.getAnnouncementDetailsUseCase,
    required this.bookmarkAnnouncementUseCase,
    required this.removeBookmarkUseCase,
    required this.likeAnnouncementUseCase,
    required this.markAnnouncementAdminRemarkUseCase,
    required this.reportAnnouncementUseCase,
    required this.removeLikeUseCase,
    required this.submitPollAnswerUseCase,
    required this.repostAnnouncementUseCase,
    required this.removeRepostUseCase,
    required this.deleteAnnouncementUseCase,
    required this.updateAnnouncementUseCase,
  }) : super(PostInitial()) {
    on<FetchPostsEvent>(_onFetchPosts);
    on<FetchAnnouncementDetailsEvent>(_onFetchAnnouncementDetails);
    on<RefreshPostsEvent>(_onRefreshPosts);
    on<BookmarkAnnouncementEvent>(_onBookmarkAnnouncement);
    on<MarkAnnouncementAdminRemarkEvent>(_onMarkAnnouncementAdminRemark);
    on<ReportAnnouncementEvent>(_onReportAnnouncement);
    on<DeleteAnnouncementEvent>(_onDeleteAnnouncement);
    on<UpdateAnnouncementEvent>(_onUpdateAnnouncement);
    on<LikeAnnouncementEvent>(_onLikeAnnouncement);
    on<RemoveLikeEvent>(_onRemoveLike);
    on<SubmitPollAnswerEvent>(_onSubmitPollAnswer);
    on<RepostAnnouncementEvent>(_onRepostAnnouncement);
    on<SyncAnnouncementCommentsEvent>(_onSyncAnnouncementComments);
  }

  String _currentPostName = 'all';
  String _currentSearchParam = '';
  int? _currentAnnouncementId;
  bool _onlyRepostedByCurrentUser = false;
  int? _repostedByUserId;
  final Map<String, _CachedPostFeed> _feedCache = {};
  _FeedOverviewCounts _lastKnownOverviewCounts = const _FeedOverviewCounts(
    allPostsCount: 0,
    myPostsCount: 0,
    praisePostsCount: 0,
  );

  Future<void> _onFetchPosts(
    FetchPostsEvent event,
    Emitter<PostState> emit,
  ) async {
    _currentPostName = event.postName;
    _currentSearchParam = event.searchParam;
    _currentAnnouncementId = null;
    _onlyRepostedByCurrentUser = event.onlyRepostedByCurrentUser;
    _repostedByUserId = event.repostedByUserId;

    final currentState = state;
    final cacheKey = _feedCacheKey(event.postName, event.searchParam);
    final cachedFeed = _feedCache[cacheKey];
    final shouldUpdateOverviewCounts = currentState is! PostLoaded;

    if (cachedFeed != null) {
      emit(
        _buildLoadedFeedState(
          feed: cachedFeed,
          currentPostName: event.postName,
          currentSearchParam: event.searchParam,
          currentAnnouncementId: null,
          onlyRepostedByCurrentUser: event.onlyRepostedByCurrentUser,
          repostedByUserId: event.repostedByUserId,
          shouldUpdateOverviewCounts: shouldUpdateOverviewCounts,
        ),
      );
      return;
    }

    if (event.showLoader || currentState is! PostLoaded) {
      emit(PostLoading());
    } else {
      emit(currentState.copyWith(clearActionFeedback: true));
    }

    final failureOrPosts = await getAnnouncementsUseCase(
      GetAnnouncementsParams(
        postName: event.postName,
        searchParam: event.searchParam,
      ),
    );

    failureOrPosts.fold((failure) => emit(PostError(failure.message)), (
      result,
    ) {
      final feed = _CachedPostFeed.fromResult(result);
      _feedCache[cacheKey] = feed;
      emit(
        _buildLoadedFeedState(
          feed: feed,
          currentPostName: event.postName,
          currentSearchParam: event.searchParam,
          currentAnnouncementId: null,
          onlyRepostedByCurrentUser: event.onlyRepostedByCurrentUser,
          repostedByUserId: event.repostedByUserId,
          shouldUpdateOverviewCounts: shouldUpdateOverviewCounts,
        ),
      );
    });
  }

  Future<void> _onFetchAnnouncementDetails(
    FetchAnnouncementDetailsEvent event,
    Emitter<PostState> emit,
  ) async {
    _currentAnnouncementId = event.announcementId;
    _currentPostName = 'details';
    _currentSearchParam = '';
    _onlyRepostedByCurrentUser = false;
    _repostedByUserId = null;

    final currentState = state;
    if (event.showLoader || currentState is! PostLoaded) {
      emit(PostLoading());
    } else {
      emit(currentState.copyWith(clearActionFeedback: true));
    }

    final result = await getAnnouncementDetailsUseCase(
      GetAnnouncementDetailsParams(announcementId: event.announcementId),
    );

    result.fold(
      (failure) => emit(PostError(failure.message)),
      (announcement) => emit(
        PostLoaded(
          [announcement],
          currentPostName: 'details',
          currentSearchParam: '',
          currentAnnouncementId: event.announcementId,
        ),
      ),
    );
  }

  Future<void> _onRefreshPosts(
    RefreshPostsEvent event,
    Emitter<PostState> emit,
  ) async {
    final currentState = state;
    if (event.showLoader || currentState is! PostLoaded) {
      emit(PostLoading());
    } else {
      emit(currentState.copyWith(clearActionFeedback: true));
    }

    if (_currentAnnouncementId != null) {
      final result = await getAnnouncementDetailsUseCase(
        GetAnnouncementDetailsParams(announcementId: _currentAnnouncementId!),
      );

      result.fold(
        (failure) => emit(PostError(failure.message)),
        (announcement) => emit(
          PostLoaded(
            [announcement],
            currentPostName: 'details',
            currentSearchParam: '',
            currentAnnouncementId: _currentAnnouncementId,
          ),
        ),
      );
      return;
    }

    final failureOrPosts = await getAnnouncementsUseCase(
      GetAnnouncementsParams(
        postName: _currentPostName,
        searchParam: _currentSearchParam,
      ),
    );

    failureOrPosts.fold((failure) => emit(PostError(failure.message)), (
      result,
    ) {
      final feed = _CachedPostFeed.fromResult(result);
      _feedCache[_feedCacheKey(_currentPostName, _currentSearchParam)] = feed;
      emit(
        _buildLoadedFeedState(
          feed: feed,
          currentPostName: _currentPostName,
          currentSearchParam: _currentSearchParam,
          currentAnnouncementId: null,
          onlyRepostedByCurrentUser: _onlyRepostedByCurrentUser,
          repostedByUserId: _repostedByUserId,
          shouldUpdateOverviewCounts: true,
        ),
      );
    });
  }

  Future<void> _onBookmarkAnnouncement(
    BookmarkAnnouncementEvent event,
    Emitter<PostState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    final previousAnnouncements = currentState.announcements;
    final hasCurrentUser = event.currentUserId != null;
    final updatedAnnouncements =
        hasCurrentUser
            ? _toggleBookmarkForAnnouncement(
              announcements: previousAnnouncements,
              announcementId: event.announcementId,
              currentUserId: event.currentUserId!,
            )
            : previousAnnouncements;
    final updatedCachedFeeds =
        hasCurrentUser
            ? _syncBookmarkAcrossCachedFeeds(
              announcementId: event.announcementId,
              currentUserId: event.currentUserId!,
            )
            : null;
    final isRemovingBookmark =
        hasCurrentUser &&
        _announcementById(
              previousAnnouncements,
              event.announcementId,
            )?.bookmarkedByUserIds?.contains(event.currentUserId) ==
            true;

    emit(
      currentState.copyWith(
        announcements: updatedAnnouncements,
        processingPostIds:
            {...currentState.processingPostIds, event.announcementId}.toList(),
        clearActionFeedback: true,
      ),
    );

    final result =
        isRemovingBookmark
            ? await removeBookmarkUseCase(
              RemoveBookmarkParams(
                announcementId: event.announcementId,
              ),
            )
            : await bookmarkAnnouncementUseCase(
              BookmarkAnnouncementParams(announcementId: event.announcementId),
            );

    result.fold(
      (failure) {
        if (updatedCachedFeeds != null) {
          _feedCache
            ..clear()
            ..addAll(updatedCachedFeeds.previousFeeds);
        }
        emit(
          currentState.copyWith(
            announcements: previousAnnouncements,
            processingPostIds:
                currentState.processingPostIds
                    .where((id) => id != event.announcementId)
                    .toList(),
            actionErrorMessage: failure.message,
          ),
        );
      },
      (success) {
        if (success) {
          if (updatedCachedFeeds != null) {
            _feedCache
              ..clear()
              ..addAll(updatedCachedFeeds.updatedFeeds);
          }
          emit(
            currentState.copyWith(
              announcements: updatedAnnouncements,
              processingPostIds:
                  currentState.processingPostIds
                      .where((id) => id != event.announcementId)
                      .toList(),
              actionMessage:
                  isRemovingBookmark
                      ? 'Bookmark removed successfully'
                      : 'Post bookmarked successfully',
            ),
          );
        } else {
          if (updatedCachedFeeds != null) {
            _feedCache
              ..clear()
              ..addAll(updatedCachedFeeds.previousFeeds);
          }
          emit(
            currentState.copyWith(
              announcements: previousAnnouncements,
              processingPostIds:
                  currentState.processingPostIds
                      .where((id) => id != event.announcementId)
                      .toList(),
              actionErrorMessage: 'Unable to update bookmark right now',
            ),
          );
        }
      },
    );
  }

  Future<void> _onDeleteAnnouncement(
    DeleteAnnouncementEvent event,
    Emitter<PostState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    emit(
      currentState.copyWith(
        processingPostIds:
            {...currentState.processingPostIds, event.announcementId}.toList(),
        clearActionFeedback: true,
      ),
    );

    final result = await deleteAnnouncementUseCase(
      DeleteAnnouncementParams(announcementId: event.announcementId),
    );

    await result.fold(
      (failure) async {
        emit(
          currentState.copyWith(
            processingPostIds:
                currentState.processingPostIds
                    .where((id) => id != event.announcementId)
                    .toList(),
            actionErrorMessage: failure.message,
          ),
        );
      },
      (success) {
        if (success) {
          emit(
            currentState.copyWith(
              announcements:
                  currentState.announcements
                      .where(
                        (announcement) =>
                            announcement.id != event.announcementId,
                      )
                      .toList(),
              processingPostIds:
                  currentState.processingPostIds
                      .where((id) => id != event.announcementId)
                      .toList(),
              actionMessage: 'Post deleted successfully',
            ),
          );
        } else {
          emit(
            currentState.copyWith(
              processingPostIds:
                  currentState.processingPostIds
                      .where((id) => id != event.announcementId)
                      .toList(),
              actionErrorMessage: 'Unable to delete post right now',
            ),
          );
        }
      },
    );
  }

  Future<void> _onReportAnnouncement(
    ReportAnnouncementEvent event,
    Emitter<PostState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    emit(
      currentState.copyWith(
        processingPostIds:
            {...currentState.processingPostIds, event.announcementId}.toList(),
        clearActionFeedback: true,
      ),
    );

    final result = await reportAnnouncementUseCase(
      ReportAnnouncementParams(
        announcementId: event.announcementId,
        reason: event.reason,
      ),
    );

    await result.fold(
      (failure) async {
        emit(
          currentState.copyWith(
            processingPostIds:
                currentState.processingPostIds
                    .where((id) => id != event.announcementId)
                    .toList(),
            actionErrorMessage: failure.message,
          ),
        );
      },
      (success) async {
        if (!success) {
          emit(
            currentState.copyWith(
              processingPostIds:
                  currentState.processingPostIds
                      .where((id) => id != event.announcementId)
                      .toList(),
              actionErrorMessage: 'Unable to report post right now',
            ),
          );
          return;
        }

        final updatedAnnouncements = currentState.announcements
            .map((announcement) {
              if (announcement.id != event.announcementId) {
                return announcement;
              }

              final updatedReportedUserIds = List<int>.from(
                announcement.reportedByUserIds,
              );
              if (event.currentUserId != null &&
                  !updatedReportedUserIds.contains(event.currentUserId)) {
                updatedReportedUserIds.add(event.currentUserId!);
              }

              return announcement.copyWith(
                reportedByUserIds: List<int>.unmodifiable(
                  updatedReportedUserIds,
                ),
                reportedByCount:
                    event.currentUserId != null
                        ? updatedReportedUserIds.length
                        : announcement.reportedByCount + 1,
              );
            })
            .toList(growable: false);

        emit(
          currentState.copyWith(
            announcements: updatedAnnouncements,
            processingPostIds:
                currentState.processingPostIds
                    .where((id) => id != event.announcementId)
                    .toList(),
            actionMessage: 'Post reported successfully',
          ),
        );
      },
    );
  }

  Future<void> _onMarkAnnouncementAdminRemark(
    MarkAnnouncementAdminRemarkEvent event,
    Emitter<PostState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    emit(
      currentState.copyWith(
        processingPostIds:
            {...currentState.processingPostIds, event.announcementId}.toList(),
        clearActionFeedback: true,
      ),
    );

    final result = await markAnnouncementAdminRemarkUseCase(
      MarkAnnouncementAdminRemarkParams(
        announcementId: event.announcementId,
        adminRemark: event.adminRemark,
      ),
    );

    await result.fold(
      (failure) async {
        emit(
          currentState.copyWith(
            processingPostIds:
                currentState.processingPostIds
                    .where((id) => id != event.announcementId)
                    .toList(),
            actionErrorMessage: failure.message,
          ),
        );
      },
      (success) async {
        if (!success) {
          emit(
            currentState.copyWith(
              processingPostIds:
                  currentState.processingPostIds
                      .where((id) => id != event.announcementId)
                      .toList(),
              actionErrorMessage: 'Unable to update post status right now',
            ),
          );
          return;
        }

        final updatedAnnouncements =
            _shouldRemoveAnnouncementAfterAdminRemark(event.adminRemark)
                ? currentState.announcements
                    .where(
                      (announcement) => announcement.id != event.announcementId,
                    )
                    .toList(growable: false)
                : currentState.announcements
                    .map((announcement) {
                      if (announcement.id != event.announcementId) {
                        return announcement;
                      }

                      return announcement.copyWith(
                        adminRemark: event.adminRemark,
                      );
                    })
                    .toList(growable: false);

        final normalizedRemark = event.adminRemark.trim().toLowerCase();
        final actionMessage =
            normalizedRemark == 'publish'
                ? 'Post published successfully'
                : normalizedRemark == 'reject'
                ? 'Post rejected successfully'
                : normalizedRemark == 'screened'
                ? 'Post marked as screened'
                : normalizedRemark == 'flagged'
                ? 'Post marked as flagged'
                : normalizedRemark == 'approved'
                ? 'Post marked as approved'
                : 'Post status updated successfully';

        final updatedProcessingPostIds =
            currentState.processingPostIds
                .where((id) => id != event.announcementId)
                .toList();

        if (_shouldRefreshAfterAdminRemark(normalizedRemark)) {
          await _refreshPostsSilently(
            emit,
            processingPostIds: updatedProcessingPostIds,
            actionMessage: actionMessage,
          );
          return;
        }

        emit(
          currentState.copyWith(
            announcements: updatedAnnouncements,
            processingPostIds: updatedProcessingPostIds,
            actionMessage: actionMessage,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateAnnouncement(
    UpdateAnnouncementEvent event,
    Emitter<PostState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    emit(
      currentState.copyWith(
        processingPostIds:
            {...currentState.processingPostIds, event.announcement.id}.toList(),
        clearActionFeedback: true,
      ),
    );

    final result = await updateAnnouncementUseCase(
      UpdateAnnouncementParams(
        announcementId: event.announcement.id,
        scheduleAnnouncement:
            event.announcement.scheduleAnnouncement ??
            event.announcement.createdAt,
        subject: event.subject.trim(),
        type: event.announcement.type ?? 'general',
        description: event.description.trim(),
        options: event.options ?? event.announcement.options,
        question: event.question?.trim() ?? event.announcement.question,
        status: event.announcement.status,
        repostThought:
            event.repostThought?.trim() ?? event.announcement.repostThought,
        isEdited: true,
      ),
    );

    await result.fold(
      (failure) async {
        emit(
          currentState.copyWith(
            processingPostIds:
                currentState.processingPostIds
                    .where((id) => id != event.announcement.id)
                    .toList(),
            actionErrorMessage: failure.message,
          ),
        );
      },
      (success) async {
        if (success) {
          final updatedAnnouncements = _syncUpdatedAnnouncement(
            announcements: currentState.announcements,
            announcementId: event.announcement.id,
            subject: event.subject.trim(),
            description: event.description.trim(),
            options: event.options,
            question: event.question?.trim(),
            repostThought: event.repostThought?.trim(),
          );
          _feedCache.updateAll(
            (_, feed) => _CachedPostFeed(
              announcements: _syncUpdatedAnnouncement(
                announcements: feed.announcements,
                announcementId: event.announcement.id,
                subject: event.subject.trim(),
                description: event.description.trim(),
                options: event.options,
                question: event.question?.trim(),
                repostThought: event.repostThought?.trim(),
              ),
              allPostsCount: feed.allPostsCount,
              myPostsCount: feed.myPostsCount,
              praisePostsCount: feed.praisePostsCount,
            ),
          );

          emit(
            currentState.copyWith(
              announcements: updatedAnnouncements,
              processingPostIds:
                  currentState.processingPostIds
                      .where((id) => id != event.announcement.id)
                      .toList(),
              actionMessage: 'Post updated successfully',
            ),
          );
          await _refreshPostsSilently(
            emit,
            processingPostIds:
                currentState.processingPostIds
                    .where((id) => id != event.announcement.id)
                    .toList(),
            actionMessage: 'Post updated successfully',
          );
        } else {
          emit(
            currentState.copyWith(
              processingPostIds:
                  currentState.processingPostIds
                      .where((id) => id != event.announcement.id)
                      .toList(),
              actionErrorMessage: 'Unable to update post right now',
            ),
          );
        }
      },
    );
  }

  Future<void> _onLikeAnnouncement(
    LikeAnnouncementEvent event,
    Emitter<PostState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    emit(
      currentState.copyWith(
        processingPostIds:
            {...currentState.processingPostIds, event.id}.toList(),
        clearActionFeedback: true,
      ),
    );

    final result = await likeAnnouncementUseCase(
      LikeAnnouncementParams(id: event.id, reaction: event.reaction),
    );

    await result.fold(
      (failure) async {
        emit(
          currentState.copyWith(
            processingPostIds:
                currentState.processingPostIds
                    .where((id) => id != event.id)
                    .toList(),
            actionErrorMessage: failure.message,
          ),
        );
      },
      (success) async {
        if (success) {
          await _refreshPostsSilently(
            emit,
            processingPostIds:
                currentState.processingPostIds
                    .where((id) => id != event.id)
                    .toList(),
          );
        } else {
          emit(
            currentState.copyWith(
              processingPostIds:
                  currentState.processingPostIds
                      .where((id) => id != event.id)
                      .toList(),
            ),
          );
        }
      },
    );
  }

  Future<void> _onRepostAnnouncement(
    RepostAnnouncementEvent event,
    Emitter<PostState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    emit(currentState.copyWith(clearActionFeedback: true));

    final isRemoveAction = event.action == RepostAnnouncementAction.remove;
    final result =
        isRemoveAction
            ? await removeRepostUseCase(
              RemoveRepostParams(announcementId: event.announcementId),
            )
            : await repostAnnouncementUseCase(
              RepostAnnouncementParams(
                announcementId: event.announcementId,
                repostThought: event.repostThought,
              ),
            );

    await result.fold(
      (failure) async {
        emit(currentState.copyWith(actionErrorMessage: failure.message));
      },
      (success) async {
        if (success) {
          await _refreshPostsSilently(
            emit,
            processingPostIds: currentState.processingPostIds,
            actionMessage:
                isRemoveAction
                    ? 'Repost removed successfully'
                    : 'Post reposted successfully',
          );
        } else {
          emit(
            currentState.copyWith(
              actionErrorMessage:
                  isRemoveAction
                      ? 'Unable to remove repost right now'
                      : 'Unable to repost right now',
            ),
          );
        }
      },
    );
  }

  Future<void> _onRemoveLike(
    RemoveLikeEvent event,
    Emitter<PostState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    emit(
      currentState.copyWith(
        processingPostIds:
            {...currentState.processingPostIds, event.announcementId}.toList(),
        clearActionFeedback: true,
      ),
    );

    final result = await removeLikeUseCase(
      RemoveLikeParams(
        likeId: event.likeId,
        announcementId: event.announcementId,
      ),
    );

    await result.fold(
      (failure) async {
        emit(
          currentState.copyWith(
            processingPostIds:
                currentState.processingPostIds
                    .where((id) => id != event.announcementId)
                    .toList(),
            actionErrorMessage: failure.message,
          ),
        );
      },
      (success) async {
        if (success) {
          await _refreshPostsSilently(
            emit,
            processingPostIds:
                currentState.processingPostIds
                    .where((id) => id != event.announcementId)
                    .toList(),
          );
        } else {
          emit(
            currentState.copyWith(
              processingPostIds:
                  currentState.processingPostIds
                      .where((id) => id != event.announcementId)
                      .toList(),
            ),
          );
        }
      },
    );
  }

  Future<void> _onSubmitPollAnswer(
    SubmitPollAnswerEvent event,
    Emitter<PostState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    emit(
      currentState.copyWith(
        processingPostIds:
            {...currentState.processingPostIds, event.announcementId}.toList(),
        clearActionFeedback: true,
      ),
    );

    final result = await submitPollAnswerUseCase(
      SubmitPollAnswerParams(
        announcementId: event.announcementId,
        userId: event.userId,
        selectedOption: event.selectedOption,
      ),
    );

    await result.fold(
      (failure) async {
        emit(
          currentState.copyWith(
            processingPostIds:
                currentState.processingPostIds
                    .where((id) => id != event.announcementId)
                    .toList(),
            actionErrorMessage: failure.message,
          ),
        );
      },
      (success) async {
        if (success) {
          await _refreshPostsSilently(
            emit,
            processingPostIds:
                currentState.processingPostIds
                    .where((id) => id != event.announcementId)
                    .toList(),
            actionMessage: 'Response recorded successfully',
          );
        } else {
          emit(
            currentState.copyWith(
              processingPostIds:
                  currentState.processingPostIds
                      .where((id) => id != event.announcementId)
                      .toList(),
              actionErrorMessage: 'Unable to submit vote right now',
            ),
          );
        }
      },
    );
  }

  Future<void> _refreshPostsSilently(
    Emitter<PostState> emit, {
    required List<int> processingPostIds,
    String? actionMessage,
  }) async {
    if (_currentAnnouncementId != null) {
      final result = await getAnnouncementDetailsUseCase(
        GetAnnouncementDetailsParams(announcementId: _currentAnnouncementId!),
      );

      result.fold(
        (_) => emit(
          (state is PostLoaded)
              ? (state as PostLoaded).copyWith(
                processingPostIds: processingPostIds,
                clearActionFeedback: true,
              )
              : PostLoaded(
                const [],
                currentPostName: 'details',
                currentSearchParam: '',
                currentAnnouncementId: _currentAnnouncementId,
              ),
        ),
        (announcement) => emit(
          PostLoaded(
            [announcement],
            processingPostIds: processingPostIds,
            actionMessage: actionMessage,
            currentPostName: 'details',
            currentSearchParam: '',
            currentAnnouncementId: _currentAnnouncementId,
          ),
        ),
      );
      return;
    }

    final failureOrPosts = await getAnnouncementsUseCase(
      GetAnnouncementsParams(
        postName: _currentPostName,
        searchParam: _currentSearchParam,
      ),
    );

    failureOrPosts.fold(
      (_) => emit(
        (state is PostLoaded)
            ? (state as PostLoaded).copyWith(
              processingPostIds: processingPostIds,
              clearActionFeedback: true,
            )
            : PostLoaded(
              const [],
              currentPostName: _currentPostName,
              currentSearchParam: _currentSearchParam,
              currentAnnouncementId: _currentAnnouncementId,
              onlyRepostedByCurrentUser: _onlyRepostedByCurrentUser,
              repostedByUserId: _repostedByUserId,
            ),
      ),
      (result) {
        final feed = _CachedPostFeed.fromResult(result);
        _feedCache[_feedCacheKey(_currentPostName, _currentSearchParam)] = feed;
        emit(
          _buildLoadedFeedState(
            feed: feed,
            processingPostIds: processingPostIds,
            actionMessage: actionMessage,
            currentPostName: _currentPostName,
            currentSearchParam: _currentSearchParam,
            currentAnnouncementId: _currentAnnouncementId,
            onlyRepostedByCurrentUser: _onlyRepostedByCurrentUser,
            repostedByUserId: _repostedByUserId,
            shouldUpdateOverviewCounts: false,
          ),
        );
      },
    );
  }

  PostLoaded _buildLoadedFeedState({
    required _CachedPostFeed feed,
    required String currentPostName,
    required String currentSearchParam,
    required int? currentAnnouncementId,
    required bool onlyRepostedByCurrentUser,
    required int? repostedByUserId,
    required bool shouldUpdateOverviewCounts,
    List<int> processingPostIds = const [],
    String? actionMessage,
  }) {
    final overviewCounts = _resolveOverviewCounts(
      feed,
      shouldUpdateOverviewCounts: shouldUpdateOverviewCounts,
    );
    final announcements = _applyAnnouncementFilters(
      announcements: feed.announcements,
      onlyRepostedByCurrentUser: onlyRepostedByCurrentUser,
      repostedByUserId: repostedByUserId,
    );

    return PostLoaded(
      announcements,
      processingPostIds: processingPostIds,
      actionMessage: actionMessage,
      currentPostName: currentPostName,
      currentSearchParam: currentSearchParam,
      currentAnnouncementId: currentAnnouncementId,
      allPostsCount: overviewCounts.allPostsCount,
      myPostsCount: overviewCounts.myPostsCount,
      praisePostsCount: overviewCounts.praisePostsCount,
      onlyRepostedByCurrentUser: onlyRepostedByCurrentUser,
      repostedByUserId: repostedByUserId,
    );
  }

  String _feedCacheKey(String postName, String searchParam) {
    return '${postName.trim().toLowerCase()}::${searchParam.trim().toLowerCase()}';
  }

  _FeedOverviewCounts _resolveOverviewCounts(
    _CachedPostFeed feed, {
    required bool shouldUpdateOverviewCounts,
  }) {
    final incomingCounts = _FeedOverviewCounts(
      allPostsCount: feed.allPostsCount,
      myPostsCount: feed.myPostsCount,
      praisePostsCount: feed.praisePostsCount,
    );

    if (shouldUpdateOverviewCounts && !incomingCounts.isZero) {
      _lastKnownOverviewCounts = incomingCounts;
    }

    return _lastKnownOverviewCounts;
  }

  List<AnnouncementEntity> _applyAnnouncementFilters({
    required List<AnnouncementEntity> announcements,
    required bool onlyRepostedByCurrentUser,
    required int? repostedByUserId,
  }) {
    if (!onlyRepostedByCurrentUser || repostedByUserId == null) {
      return announcements;
    }

    return announcements
        .where(
          (announcement) =>
              announcement.repostedBy == repostedByUserId ||
              announcement.repostedByUser?.id == repostedByUserId,
        )
        .toList(growable: false);
  }

  void _onSyncAnnouncementComments(
    SyncAnnouncementCommentsEvent event,
    Emitter<PostState> emit,
  ) {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    final updatedComments = List<CommentEntity>.unmodifiable(event.comments);
    final updatedAnnouncements =
        currentState.announcements.map((announcement) {
          if (announcement.id != event.announcementId) {
            return announcement;
          }

          return announcement.copyWith(
            comments: updatedComments,
            totalComments: updatedComments.length,
          );
        }).toList();

    emit(currentState.copyWith(announcements: updatedAnnouncements));
  }

  AnnouncementEntity? _announcementById(
    List<AnnouncementEntity> announcements,
    int announcementId,
  ) {
    for (final announcement in announcements) {
      if (announcement.id == announcementId) {
        return announcement;
      }
    }
    return null;
  }

  _CachedFeedBookmarkUpdate _syncBookmarkAcrossCachedFeeds({
    required int announcementId,
    required int currentUserId,
  }) {
    final previousFeeds = Map<String, _CachedPostFeed>.from(_feedCache);
    final updatedFeeds = <String, _CachedPostFeed>{};

    for (final entry in _feedCache.entries) {
      updatedFeeds[entry.key] = _CachedPostFeed(
        announcements: _toggleBookmarkForAnnouncement(
          announcements: entry.value.announcements,
          announcementId: announcementId,
          currentUserId: currentUserId,
        ),
        allPostsCount: entry.value.allPostsCount,
        myPostsCount: entry.value.myPostsCount,
        praisePostsCount: entry.value.praisePostsCount,
      );
    }

    return _CachedFeedBookmarkUpdate(
      previousFeeds: previousFeeds,
      updatedFeeds: updatedFeeds,
    );
  }

  List<AnnouncementEntity> _toggleBookmarkForAnnouncement({
    required List<AnnouncementEntity> announcements,
    required int announcementId,
    required int currentUserId,
  }) {
    return announcements
        .map((announcement) {
          if (announcement.id != announcementId) {
            return announcement;
          }

          final bookmarkedByUserIds = List<int>.from(
            announcement.bookmarkedByUserIds ?? const <int>[],
          );

          if (bookmarkedByUserIds.contains(currentUserId)) {
            bookmarkedByUserIds.removeWhere((id) => id == currentUserId);
          } else {
            bookmarkedByUserIds.add(currentUserId);
          }

          return announcement.copyWith(
            bookmarkedByUserIds: List<int>.unmodifiable(bookmarkedByUserIds),
          );
        })
        .toList(growable: false);
  }

  List<AnnouncementEntity> _syncUpdatedAnnouncement({
    required List<AnnouncementEntity> announcements,
    required int announcementId,
    required String subject,
    required String description,
    List<String>? options,
    String? question,
    String? repostThought,
  }) {
    return announcements.map((announcement) {
      if (announcement.id != announcementId) {
        return announcement;
      }

      return announcement.copyWith(
        subject: subject,
        description: description,
        options: options ?? announcement.options,
        question: question ?? announcement.question,
        repostThought: repostThought ?? announcement.repostThought,
        isEdited: true,
      );
    }).toList(growable: false);
  }

  bool _shouldRemoveAnnouncementAfterAdminRemark(String adminRemark) {
    final normalizedRemark = adminRemark.trim().toLowerCase();
    return _currentAnnouncementId == null &&
        _currentPostName == 'pending_approval' &&
        (normalizedRemark == 'publish' || normalizedRemark == 'reject');
  }

  bool _shouldRefreshAfterAdminRemark(String adminRemark) {
    return _currentAnnouncementId == null &&
        _currentPostName == 'report' &&
        adminRemark == 'approved';
  }
}

class _CachedFeedBookmarkUpdate {
  final Map<String, _CachedPostFeed> previousFeeds;
  final Map<String, _CachedPostFeed> updatedFeeds;

  const _CachedFeedBookmarkUpdate({
    required this.previousFeeds,
    required this.updatedFeeds,
  });
}
