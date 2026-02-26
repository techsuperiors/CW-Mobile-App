import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/attendance_regularize_result.dart';

/// Attendance Regularize repository interface
abstract class AttendanceRegularizeRepository {
  Future<Either<Failure, AttendanceRegularizeResult>> applyRegularize({
    required String requestDate,
    required int requestTo,
    required String requestFor,
    required String modeType,
    required String checkIn,
    required String checkOut,
    required String reason,
    required String description,
    required int userId,
    required bool isOther,
    required int statusUpdatedBy,
  });
}
