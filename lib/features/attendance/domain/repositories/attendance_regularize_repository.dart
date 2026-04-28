import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/attendance_request_comment.dart';
import '../entities/attendance_regularize_detail.dart';
import '../entities/attendance_regularize_result.dart';

/// Attendance Regularize repository interface
abstract class AttendanceRegularizeRepository {
  Future<Either<Failure, AttendanceRegularizeResult>> applyRegularize({
    required String requestDate,
    required String requestFor,
    required String modeType,
    String? checkIn,
    String? checkOut,
    required String reason,
    String? otherReason,
    required String description,
    required int userId,
    required bool isOther,
    int? statusUpdatedBy,
  });

  Future<Either<Failure, AttendanceRegularizeDetail>> getRegularizeRequestDetail(
    int requestId,
  );

  Future<Either<Failure, AttendanceRegularizeResult>> updateRegularize({
    required int id,
    required String requestFor,
    required String requestDate,
    String? checkIn,
    String? checkOut,
    required int statusUpdatedBy,
    required String description,
  });

  Future<Either<Failure, String>> updateRegularizeRequestStatus({
    required int requestId,
    required String status,
  });

  Future<Either<Failure, List<AttendanceRequestComment>>> getRequestComments({
    required int clientId,
    required int requestId,
  });

  Future<Either<Failure, String>> addRequestComment({
    required int requestId,
    required String comment,
    String type = 'Attendance',
  });
}
