import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class RepostAnnouncementUseCase {
  final PostRepository repository;

  RepostAnnouncementUseCase(this.repository);

  Future<Either<Failure, bool>> call(RepostAnnouncementParams params) {
    return repository.repostAnnouncement(
      announcementId: params.announcementId,
      repostThought: params.repostThought,
    );
  }
}

class RepostAnnouncementParams {
  final int announcementId;
  final String? repostThought;

  RepostAnnouncementParams({
    required this.announcementId,
    this.repostThought,
  });
}
