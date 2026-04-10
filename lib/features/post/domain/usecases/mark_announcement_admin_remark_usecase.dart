import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class MarkAnnouncementAdminRemarkUseCase {
  final PostRepository repository;

  MarkAnnouncementAdminRemarkUseCase(this.repository);

  Future<Either<Failure, bool>> call(
    MarkAnnouncementAdminRemarkParams params,
  ) {
    return repository.markAnnouncementAdminRemark(
      announcementId: params.announcementId,
      adminRemark: params.adminRemark,
    );
  }
}

class MarkAnnouncementAdminRemarkParams {
  final int announcementId;
  final String adminRemark;

  MarkAnnouncementAdminRemarkParams({
    required this.announcementId,
    required this.adminRemark,
  });
}
