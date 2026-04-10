import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class RemoveBookmarkUseCase {
  final PostRepository repository;

  RemoveBookmarkUseCase(this.repository);

  Future<Either<Failure, bool>> call(RemoveBookmarkParams params) {
    return repository.removeBookmark(announcementId: params.announcementId);
  }
}

class RemoveBookmarkParams {
  final int announcementId;

  const RemoveBookmarkParams({
    required this.announcementId,
  });
}
