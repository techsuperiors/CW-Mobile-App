import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class LikeAnnouncementUseCase {
  final PostRepository repository;

  LikeAnnouncementUseCase(this.repository);

  Future<Either<Failure, bool>> call(LikeAnnouncementParams params) {
    return repository.likeAnnouncement(
      id: params.id,
      reaction: params.reaction,
    );
  }
}

class LikeAnnouncementParams {
  final int id;
  final String reaction;

  LikeAnnouncementParams({
    required this.id,
    required this.reaction,
  });
}
