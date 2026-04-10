import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class RemoveLikeUseCase {
  final PostRepository repository;

  RemoveLikeUseCase(this.repository);

  Future<Either<Failure, bool>> call(RemoveLikeParams params) {
    return repository.removeLike(
      likeId: params.likeId,
      announcementId: params.announcementId,
    );
  }
}

class RemoveLikeParams {
  final int likeId;
  final int announcementId;

  RemoveLikeParams({
    required this.likeId,
    required this.announcementId,
  });
}
