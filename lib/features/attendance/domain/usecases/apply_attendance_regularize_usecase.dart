import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/attendance_regularize_result.dart';
import '../repositories/attendance_regularize_repository.dart';

/// Use case for applying attendance regularization
class ApplyAttendanceRegularizeUseCase {
  final AttendanceRegularizeRepository repository;

  ApplyAttendanceRegularizeUseCase(this.repository);

  Future<Either<Failure, AttendanceRegularizeResult>> call({
    required String requestDate,
    required String requestFor,
    required String modeType,
    required String checkIn,
    required String checkOut,
    required String reason,
    String? otherReason,
    required String description,
    required int userId,
    required bool isOther,
    required int statusUpdatedBy,
  }) {
    return repository.applyRegularize(
      requestDate: requestDate,
      requestFor: requestFor,
      modeType: modeType,
      checkIn: checkIn,
      checkOut: checkOut,
      reason: reason,
      otherReason: otherReason,
      description: description,
      userId: userId,
      isOther: isOther,
      statusUpdatedBy: statusUpdatedBy,
    );
  }
}
