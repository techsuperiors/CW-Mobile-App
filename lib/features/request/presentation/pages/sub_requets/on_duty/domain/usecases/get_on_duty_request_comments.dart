import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../repositories/on_duty_repository.dart';

class GetOnDutyRequestCommentsUseCase {
  final OnDutyRepository repository;

  GetOnDutyRequestCommentsUseCase(this.repository);

  Future<Either<Failure, List<AttendanceRequestComment>>> call({
    required int clientId,
    required int requestId,
    String type = 'OnDuty',
  }) {
    return repository.getRequestComments(
      clientId: clientId,
      requestId: requestId,
      type: type,
    );
  }
}
