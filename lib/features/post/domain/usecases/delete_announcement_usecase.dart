import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class DeleteAnnouncementUseCase {
  final PostRepository repository;

  DeleteAnnouncementUseCase(this.repository);

  Future<Either<Failure, bool>> call(DeleteAnnouncementParams params) {
    return repository.deleteAnnouncement(
      announcementId: params.announcementId,
    );
  }
}

class DeleteAnnouncementParams {
  final int announcementId;

  DeleteAnnouncementParams({
    required this.announcementId,
  });
}
