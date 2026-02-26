import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/punch_in_result.dart';

/// Attendance repository interface
abstract class AttendanceRepository {
  Future<Either<Failure, PunchInResult>> punchIn({
    required String punchInLocation,
    required double latitude,
    required double longitude,
    required String punchType,
  });

  Future<Either<Failure, PunchInResult>> punchOut({
    required String punchOutLocation,
    required double latitude,
    required double longitude,
  });
}

