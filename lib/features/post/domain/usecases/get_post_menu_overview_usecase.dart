import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/post_menu_overview_entity.dart';
import '../repositories/post_repository.dart';

class GetPostMenuOverviewUseCase
    extends UseCase<PostMenuOverviewEntity, GetPostMenuOverviewParams> {
  final PostRepository repository;

  GetPostMenuOverviewUseCase(this.repository);

  @override
  Future<Either<Failure, PostMenuOverviewEntity>> call(
    GetPostMenuOverviewParams params,
  ) async {
    return repository.getPostMenuOverview(
      currentUserId: params.currentUserId,
      searchParam: params.searchParam,
    );
  }
}

class GetPostMenuOverviewParams extends Params {
  final int currentUserId;
  final String searchParam;

  const GetPostMenuOverviewParams({
    required this.currentUserId,
    this.searchParam = '',
  });

  @override
  List<Object?> get props => [currentUserId, searchParam];
}
