import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/attendance_regularize_repository.dart';

class AddAttendanceRequestCommentUseCase {
  final AttendanceRegularizeRepository repository;

  AddAttendanceRequestCommentUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int requestId,
    required String comment,
    String type = 'Attendance',
  }) {
    return repository.addRequestComment(
      requestId: requestId,
      comment: comment,
      type: type,
    );
  }
}
