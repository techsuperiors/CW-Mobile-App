import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/punch_in_result.dart';
import '../repositories/attendance_repository.dart';

/// Use case for punching out
class PunchOutUseCase {
  final AttendanceRepository repository;

  PunchOutUseCase(this.repository);

  Future<Either<Failure, PunchInResult>> call({
    String? punchOutLocation,
    double? latitude,
    double? longitude,
    bool needsAddressResolution = false,
  }) {
    return repository.punchOut(
      punchOutLocation: punchOutLocation,
      latitude: latitude,
      longitude: longitude,
      needsAddressResolution: needsAddressResolution,
    );
  }
}
