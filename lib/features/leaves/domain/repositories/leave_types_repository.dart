import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/leave_type.dart';
import '../entities/leave_apply_result.dart';

/// Leave Types repository interface
abstract class LeaveTypesRepository {
  Future<Either<Failure, LeaveTypes>> getLeaveTypes(int userId);
  Future<Either<Failure, LeaveApplyResult>> applyLeave({
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
  });
}

