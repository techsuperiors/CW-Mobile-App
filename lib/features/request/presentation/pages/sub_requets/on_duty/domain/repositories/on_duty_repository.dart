import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../models/on_duty_request_model.dart';
import '../../models/on_duty_request_stats_model.dart';
import '../entities/on_duty_detail.dart';

abstract class OnDutyRepository {
  Future<Either<Failure, List<OnDutyRequestModel>>> getOnDutyRequests({
    required int clientId,
    int page = 1,
    int limit = 5,
    OnDutyStatus? status,
  });

  Future<Either<Failure, List<OnDutyRequestModel>>> getTeamOnDutyRequests({
    required int clientId,
    int page = 1,
    int limit = 50,
    String requestType = 'All',
    OnDutyStatus? status,
  });

  Future<Either<Failure, OnDutyRequestStatsModel>> getOnDutyRequestStats({
    required int clientId,
    String requestType = 'User',
  });

  Future<Either<Failure, OnDutyDetail>> getOnDutyRequestDetail(int requestId);

  Future<Either<Failure, String>> updateOnDutyRequestStatus({
    required int requestId,
    required String status,
  });

  Future<Either<Failure, List<AttendanceRequestComment>>> getRequestComments({
    required int clientId,
    required int requestId,
    String type = 'OnDuty',
  });

  Future<Either<Failure, String>> addRequestComment({
    required int requestId,
    required String comment,
    String type = 'OnDuty',
  });

  Future<Either<Failure, String>> raiseOnDutyRequest({
    required String subject,
    required String requestType,
    required String description,
    required String startDate,
    required String endDate,
    required String startHalf,
    required String endHalf,
    required int userId,
  });
}
