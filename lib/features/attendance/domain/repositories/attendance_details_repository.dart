import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/attendance_details.dart';

/// Attendance Details repository interface
abstract class AttendanceDetailsRepository {
  Future<Either<Failure, AttendanceDetails>> getAttendanceDetails();
}

