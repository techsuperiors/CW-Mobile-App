import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../repositories/overtime_repository.dart';

class GetOvertimeRequestCommentsUseCase {
  final OvertimeRepository repository;

  GetOvertimeRequestCommentsUseCase(this.repository);

  Future<Either<Failure, List<AttendanceRequestComment>>> call({
    required int clientId,
    required int requestId,
  }) {
    return repository.getRequestComments(
      clientId: clientId,
      requestId: requestId,
    );
  }
}
