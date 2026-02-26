import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/leave_apply_result.dart';
import '../repositories/leave_types_repository.dart';

/// Use case for applying leave
class ApplyLeaveUseCase {
  final LeaveTypesRepository repository;

  ApplyLeaveUseCase(this.repository);

  Future<Either<Failure, LeaveApplyResult>> call({
    required String leaveType,
    required String clubing,
    required bool isClubbing,
    required String startDate,
    required String endDate,
    required String subject,
    required String reason,
    required String startHalf,
    required String endHalf,
    required String dayType,
    required String description,
    required String shortCode,
    required int requestTo,
    required List<String> rHDates,
  }) async {
    return await repository.applyLeave(
      leaveType: leaveType,
      clubing: clubing,
      isClubbing: isClubbing,
      startDate: startDate,
      endDate: endDate,
      subject: subject,
      reason: reason,
      startHalf: startHalf,
      endHalf: endHalf,
      dayType: dayType,
      description: description,
      shortCode: shortCode,
      requestTo: requestTo,
      rHDates: rHDates,
    );
  }
}
