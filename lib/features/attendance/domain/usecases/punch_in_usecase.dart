import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/punch_in_result.dart';
import '../repositories/attendance_repository.dart';

/// Use case for punching in
class PunchInUseCase {
  final AttendanceRepository repository;

  PunchInUseCase(this.repository);

  Future<Either<Failure, PunchInResult>> call({
    required String punchInLocation,
    required double latitude,
    required double longitude,
    required String punchType,
  }) {
    return repository.punchIn(
      punchInLocation: punchInLocation,
      latitude: latitude,
      longitude: longitude,
      punchType: punchType,
    );
  }
}

