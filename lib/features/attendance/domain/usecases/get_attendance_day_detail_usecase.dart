import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/attendance_day_detail.dart';
import '../repositories/attendance_details_repository.dart';

class GetAttendanceDayDetailUseCase {
  final AttendanceDetailsRepository repository;

  GetAttendanceDayDetailUseCase(this.repository);

  Future<Either<Failure, AttendanceDayDetail>> call({
    required int userId,
    required String date,
  }) {
    return repository.getAttendanceDayDetail(userId: userId, date: date);
  }
}
