import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/leave_apply_result.dart';
import '../repositories/leave_types_repository.dart';

class UpdateLeaveUseCase {
  final LeaveTypesRepository repository;

  UpdateLeaveUseCase(this.repository);

  Future<Either<Failure, LeaveApplyResult>> call({
    required int leaveId,
    required String leaveType,
    required List<String?> clubing,
    required bool isClubbing,
    required String startDate,
    required String? endDate,
    required String subject,
    required String reason,
    required String startHalf,
    required String endHalf,
    required String dayType,
    required String description,
    required int requestTo,
  }) async {
    return repository.updateLeave(
      leaveId: leaveId,
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
      requestTo: requestTo,
    );
  }
}
