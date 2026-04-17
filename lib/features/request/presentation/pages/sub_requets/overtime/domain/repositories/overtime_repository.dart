import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../models/overtime_request_model.dart';
import '../../models/overtime_request_stats_model.dart';
import '../entities/overtime_detail.dart';

abstract class OvertimeRepository {
  Future<Either<Failure, List<OvertimeRequestModel>>> getOvertimeRequests({
    required int clientId,
    int page = 1,
    int limit = 5,
    OvertimeStatus? status,
  });

  Future<Either<Failure, List<OvertimeRequestModel>>> getTeamOvertimeRequests({
    required int clientId,
    int page = 1,
    int limit = 20,
    String requestType = 'All',
    OvertimeStatus? status,
  });

  Future<Either<Failure, OvertimeRequestStatsModel>> getOvertimeRequestStats({
    required int clientId,
    String requestType = 'User',
  });

  Future<Either<Failure, OvertimeDetail>> getOvertimeRequestDetail(int requestId);

  Future<Either<Failure, String>> createOvertimeRequest({
    required String requestDate,
    required String checkIn,
    required String checkOut,
    required String subject,
    required String description,
    required int userId,
  });

  Future<Either<Failure, String>> updateOvertimeRequest({
    required int requestId,
    required String requestDate,
    required String checkIn,
    required String checkOut,
    required int userId,
    required String description,
  });

  Future<Either<Failure, String>> withdrawOvertimeRequest({
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
  });
}
