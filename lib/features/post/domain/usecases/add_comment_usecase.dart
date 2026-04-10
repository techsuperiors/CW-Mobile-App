import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/announcement_entity.dart';
import '../repositories/post_repository.dart';

class AddCommentUseCase {
  final PostRepository repository;

  AddCommentUseCase(this.repository);

  Future<Either<Failure, CommentEntity>> call(AddCommentParams params) {
    return repository.addComment(
      announcementId: params.announcementId,
      comment: params.comment,
    );
  }
}

class AddCommentParams {
  final int announcementId;
  final String comment;

  AddCommentParams({
    required this.announcementId,
    required this.comment,
  });
}
