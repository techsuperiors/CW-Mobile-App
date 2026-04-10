import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class ReportAnnouncementUseCase {
  final PostRepository repository;

  ReportAnnouncementUseCase(this.repository);

  Future<Either<Failure, bool>> call(ReportAnnouncementParams params) {
    return repository.reportAnnouncement(
      announcementId: params.announcementId,
      reason: params.reason,
    );
  }
}

class ReportAnnouncementParams {
  final int announcementId;
  final String reason;

  ReportAnnouncementParams({
    required this.announcementId,
    required this.reason,
  });
}
