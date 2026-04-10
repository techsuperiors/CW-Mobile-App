import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class UpdateCommentUseCase {
  final PostRepository repository;

  UpdateCommentUseCase(this.repository);

  Future<Either<Failure, bool>> call(UpdateCommentParams params) {
    return repository.updateComment(
      commentId: params.commentId,
      comment: params.comment,
      isEdited: params.isEdited,
    );
  }
}

class UpdateCommentParams {
  final int commentId;
  final String comment;
  final bool isEdited;

  UpdateCommentParams({
    required this.commentId,
    required this.comment,
    required this.isEdited,
  });
}
