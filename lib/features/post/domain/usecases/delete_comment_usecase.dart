import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class DeleteCommentUseCase {
  final PostRepository repository;

  DeleteCommentUseCase(this.repository);

  Future<Either<Failure, bool>> call(DeleteCommentParams params) {
    return repository.deleteComment(
      commentId: params.commentId,
    );
  }
}

class DeleteCommentParams {
  final int commentId;

  DeleteCommentParams({
    required this.commentId,
  });
}
