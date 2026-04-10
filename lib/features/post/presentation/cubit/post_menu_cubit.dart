import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/post_menu_overview_entity.dart';
import '../../domain/usecases/get_post_menu_overview_usecase.dart';

enum PostMenuStatus { initial, loading, loaded, error }

class PostMenuState extends Equatable {
  final PostMenuStatus status;
  final PostMenuOverviewEntity? overview;
  final String errorMessage;
  final String searchParam;

  const PostMenuState({
    this.status = PostMenuStatus.initial,
    this.overview,
    this.errorMessage = '',
    this.searchParam = '',
  });

  PostMenuState copyWith({
    PostMenuStatus? status,
    PostMenuOverviewEntity? overview,
    String? errorMessage,
    String? searchParam,
  }) {
    return PostMenuState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      errorMessage: errorMessage ?? this.errorMessage,
      searchParam: searchParam ?? this.searchParam,
    );
  }

  @override
  List<Object?> get props => [status, overview, errorMessage, searchParam];
}

class PostMenuCubit extends Cubit<PostMenuState> {
  final GetPostMenuOverviewUseCase getPostMenuOverviewUseCase;
  final int currentUserId;

  PostMenuCubit({
    required this.getPostMenuOverviewUseCase,
    required this.currentUserId,
  }) : super(const PostMenuState());

  Future<void> fetchOverview({String searchParam = ''}) async {
    emit(
      state.copyWith(
        status: PostMenuStatus.loading,
        errorMessage: '',
        searchParam: searchParam,
      ),
    );

    final result = await getPostMenuOverviewUseCase(
      GetPostMenuOverviewParams(
        currentUserId: currentUserId,
        searchParam: searchParam,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PostMenuStatus.error,
          errorMessage: failure.message,
          searchParam: searchParam,
        ),
      ),
      (overview) => emit(
        state.copyWith(
          status: PostMenuStatus.loaded,
          overview: overview,
          errorMessage: '',
          searchParam: searchParam,
        ),
      ),
    );
  }
}
