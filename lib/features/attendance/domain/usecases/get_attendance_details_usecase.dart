import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/attendance_details.dart';
import '../repositories/attendance_details_repository.dart';

/// Get attendance details use case
class GetAttendanceDetailsUseCase {
  final AttendanceDetailsRepository repository;

  GetAttendanceDetailsUseCase(this.repository);

  Future<Either<Failure, AttendanceDetails>> call() async {
    return await repository.getAttendanceDetails();
  }
}
