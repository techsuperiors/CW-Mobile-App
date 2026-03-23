import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/attendance_regularize_detail.dart';
import '../repositories/attendance_regularize_repository.dart';

class GetRegularizeRequestDetailUseCase {
  final AttendanceRegularizeRepository repository;

  GetRegularizeRequestDetailUseCase(this.repository);

  Future<Either<Failure, AttendanceRegularizeDetail>> call(int requestId) {
    return repository.getRegularizeRequestDetail(requestId);
  }
}
