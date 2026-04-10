import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/announcement_entity.dart';
import '../repositories/post_repository.dart';

class GetBookmarkedAnnouncementsUseCase
    extends
        UseCase<List<AnnouncementEntity>, GetBookmarkedAnnouncementsParams> {
  final PostRepository repository;

  GetBookmarkedAnnouncementsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AnnouncementEntity>>> call(
    GetBookmarkedAnnouncementsParams params,
  ) async {
    return repository.getBookmarkedAnnouncements(
      currentUserId: params.currentUserId,
      searchParam: params.searchParam,
    );
  }
}

class GetBookmarkedAnnouncementsParams extends Params {
  final int currentUserId;
  final String searchParam;

  const GetBookmarkedAnnouncementsParams({
    required this.currentUserId,
    required this.searchParam,
  });

  @override
  List<Object?> get props => [currentUserId, searchParam];
}
