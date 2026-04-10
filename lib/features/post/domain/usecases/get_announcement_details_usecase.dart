import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/announcement_entity.dart';
import '../repositories/post_repository.dart';

class GetAnnouncementDetailsUseCase {
  final PostRepository repository;

  GetAnnouncementDetailsUseCase(this.repository);

  Future<Either<Failure, AnnouncementEntity>> call(
    GetAnnouncementDetailsParams params,
  ) {
    return repository.getAnnouncementDetails(
      announcementId: params.announcementId,
    );
  }
}

class GetAnnouncementDetailsParams {
  final int announcementId;

  GetAnnouncementDetailsParams({
    required this.announcementId,
  });
}
