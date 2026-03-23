import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/attendance_regularize_result.dart';
import '../repositories/attendance_regularize_repository.dart';

class UpdateAttendanceRegularizeUseCase {
  final AttendanceRegularizeRepository repository;

  UpdateAttendanceRegularizeUseCase(this.repository);

  Future<Either<Failure, AttendanceRegularizeResult>> call({
    required int id,
    required String requestFor,
    required String requestDate,
    required String checkIn,
    required String checkOut,
    required int statusUpdatedBy,
    required String description,
  }) {
    return repository.updateRegularize(
      id: id,
      requestFor: requestFor,
      requestDate: requestDate,
      checkIn: checkIn,
      checkOut: checkOut,
      statusUpdatedBy: statusUpdatedBy,
      description: description,
    );
  }
}
