import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/attendance_regularize_repository.dart';

class UpdateRegularizeRequestStatusUseCase {
  final AttendanceRegularizeRepository repository;

  UpdateRegularizeRequestStatusUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int requestId,
    required String status,
  }) {
    return repository.updateRegularizeRequestStatus(
      requestId: requestId,
      status: status,
    );
  }
}
