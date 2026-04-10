import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/post_feed_result_entity.dart';
import '../repositories/post_repository.dart';

class GetAnnouncementsUseCase
    extends UseCase<PostFeedResultEntity, GetAnnouncementsParams> {
  final PostRepository repository;

  GetAnnouncementsUseCase(this.repository);

  @override
  Future<Either<Failure, PostFeedResultEntity>> call(
    GetAnnouncementsParams params,
  ) async {
    return await repository.getAnnouncements(
      postName: params.postName,
      searchParam: params.searchParam,
    );
  }
}

class GetAnnouncementsParams extends Params {
  final String postName;
  final String searchParam;

  const GetAnnouncementsParams({
    required this.postName,
    required this.searchParam,
  });

  @override
  List<Object?> get props => [postName, searchParam];
}
