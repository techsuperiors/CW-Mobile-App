import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/punch_in_result.dart';

/// Attendance repository interface
abstract class AttendanceRepository {
  Future<Either<Failure, PunchInResult>> punchIn({
    String? punchInLocation,
    double? latitude,
    double? longitude,
    required String punchType,
    bool needsAddressResolution = false,
  });

  Future<Either<Failure, PunchInResult>> punchOut({
    String? punchOutLocation,
    double? latitude,
    double? longitude,
    bool needsAddressResolution = false,
  });

  Future<bool> syncPendingActions();

  Future<bool> hasPendingActions();
}
