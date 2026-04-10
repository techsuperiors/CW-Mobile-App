import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class ReactToCommentUseCase {
  final PostRepository repository;

  ReactToCommentUseCase(this.repository);

  Future<Either<Failure, bool>> call(ReactToCommentParams params) {
    return repository.reactToComment(
      announcementId: params.announcementId,
      commentId: params.commentId,
      reaction: params.reaction,
    );
  }
}

class ReactToCommentParams {
  final int announcementId;
  final int commentId;
  final String reaction;

  ReactToCommentParams({
    required this.announcementId,
    required this.commentId,
    required this.reaction,
  });
}
