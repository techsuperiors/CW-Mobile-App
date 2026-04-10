import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/usecases/get_bookmarked_announcements_usecase.dart';

abstract class BookmarkedPostsEvent extends Equatable {
  const BookmarkedPostsEvent();

  @override
  List<Object?> get props => [];
}

class FetchBookmarkedPostsEvent extends BookmarkedPostsEvent {
  const FetchBookmarkedPostsEvent();
}

class SearchBookmarkedPostsEvent extends BookmarkedPostsEvent {
  final String searchParam;

  const SearchBookmarkedPostsEvent({
    this.searchParam = '',
  });

  @override
  List<Object?> get props => [searchParam];
}

abstract class BookmarkedPostsState extends Equatable {
  const BookmarkedPostsState();

  @override
  List<Object?> get props => [];
}

class BookmarkedPostsInitial extends BookmarkedPostsState {}

class BookmarkedPostsLoading extends BookmarkedPostsState {}

class BookmarkedPostsLoaded extends BookmarkedPostsState {
  final List<AnnouncementEntity> announcements;

  const BookmarkedPostsLoaded(this.announcements);

  @override
  List<Object?> get props => [announcements];
}

class BookmarkedPostsError extends BookmarkedPostsState {
  final String message;

  const BookmarkedPostsError(this.message);

  @override
  List<Object?> get props => [message];
}

class BookmarkedPostsBloc
    extends Bloc<BookmarkedPostsEvent, BookmarkedPostsState> {
  final GetBookmarkedAnnouncementsUseCase getBookmarkedAnnouncementsUseCase;
  final int currentUserId;

  BookmarkedPostsBloc({
    required this.getBookmarkedAnnouncementsUseCase,
    required this.currentUserId,
  }) : super(BookmarkedPostsInitial()) {
    on<FetchBookmarkedPostsEvent>(_onFetchBookmarkedPosts);
    on<SearchBookmarkedPostsEvent>(_onSearchBookmarkedPosts);
  }

  List<AnnouncementEntity> _allBookmarkedPosts = const [];
  String _currentSearchParam = '';

  Future<void> _onFetchBookmarkedPosts(
    FetchBookmarkedPostsEvent event,
    Emitter<BookmarkedPostsState> emit,
  ) async {
    emit(BookmarkedPostsLoading());

    final result = await getBookmarkedAnnouncementsUseCase(
      GetBookmarkedAnnouncementsParams(
        currentUserId: currentUserId,
        searchParam: '',
      ),
    );

    result.fold(
      (failure) => emit(BookmarkedPostsError(failure.message)),
      (posts) {
        _allBookmarkedPosts = List<AnnouncementEntity>.unmodifiable(posts);
        emit(
          BookmarkedPostsLoaded(
            _applyLocalFilter(
              announcements: _allBookmarkedPosts,
              searchParam: _currentSearchParam,
            ),
          ),
        );
      },
    );
  }

  void _onSearchBookmarkedPosts(
    SearchBookmarkedPostsEvent event,
    Emitter<BookmarkedPostsState> emit,
  ) {
    _currentSearchParam = event.searchParam.trim();

    emit(
      BookmarkedPostsLoaded(
        _applyLocalFilter(
          announcements: _allBookmarkedPosts,
          searchParam: _currentSearchParam,
        ),
      ),
    );
  }

  List<AnnouncementEntity> _applyLocalFilter({
    required List<AnnouncementEntity> announcements,
    required String searchParam,
  }) {
    final normalizedSearch = searchParam.trim().toLowerCase();
    if (normalizedSearch.isEmpty) {
      return announcements;
    }

    return announcements.where((announcement) {
      final authorName =
          announcement.createdByUser?.fullName.trim().toLowerCase() ?? '';
      final subject = announcement.subject.trim().toLowerCase();
      final description = announcement.description.trim().toLowerCase();
      final question = (announcement.question ?? '').trim().toLowerCase();

      return authorName.contains(normalizedSearch) ||
          subject.contains(normalizedSearch) ||
          description.contains(normalizedSearch) ||
          question.contains(normalizedSearch);
    }).toList(growable: false);
  }
}
