import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/leave_type.dart';
import '../entities/leave_apply_result.dart';
import '../entities/leave_uploaded_file.dart';

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
    required String? startHalf,
    required String? endHalf,
    required String dayType,
    required String description,
    required String shortCode,
    required int requestTo,
    required List<String> rHDates,
    String? leaveStartTime,
    String? leaveEndTime,
    List<File> attachmentFiles,
  });
  Future<Either<Failure, LeaveApplyResult>> updateLeave({
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
    String? leaveStartTime,
    String? leaveEndTime,
  });
  Future<Either<Failure, List<LeaveUploadedFile>>> uploadLeaveFiles({
    required int leaveId,
    required List<File> files,
  });
  Future<Either<Failure, String>> deleteLeaveFile({
    required int leaveFileId,
    required String fileId,
  });
}
