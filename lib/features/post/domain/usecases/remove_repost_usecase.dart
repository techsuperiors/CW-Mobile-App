import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class RemoveRepostUseCase {
  final PostRepository repository;

  RemoveRepostUseCase(this.repository);

  Future<Either<Failure, bool>> call(RemoveRepostParams params) {
    return repository.removeRepost(
      announcementId: params.announcementId,
    );
  }
}

class RemoveRepostParams {
  final int announcementId;

  RemoveRepostParams({
    required this.announcementId,
  });
}
