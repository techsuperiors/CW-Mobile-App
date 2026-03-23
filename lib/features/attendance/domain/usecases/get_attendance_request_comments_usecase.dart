import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/attendance_request_comment.dart';
import '../repositories/attendance_regularize_repository.dart';

class GetAttendanceRequestCommentsUseCase {
  final AttendanceRegularizeRepository repository;

  GetAttendanceRequestCommentsUseCase(this.repository);

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
