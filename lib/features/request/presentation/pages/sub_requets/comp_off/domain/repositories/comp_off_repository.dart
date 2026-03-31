import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../models/comp_off_request_model.dart';
import '../../models/comp_off_request_stats_model.dart';
import '../entities/comp_off_detail.dart';

abstract class CompOffRepository {
  Future<Either<Failure, List<CompOffRequestModel>>> getCompOffRequests();
  Future<Either<Failure, List<CompOffRequestModel>>> getTeamCompOffRequests({
    int page = 1,
    int limit = 20,
    String requestType = 'All',
  });
  Future<Either<Failure, CompOffRequestStatsModel>> getCompOffRequestStats({
    required int userId,
  });
  Future<Either<Failure, CompOffDetail>> getCompOffDetail(int compOffId);
  Future<Either<Failure, String>> createCompOffRequest({
    required String type,
    required String date,
    required String duration,
    required String reason,
    required String subject,
    required int requestTo,
    required int userId,
  });
  Future<Either<Failure, String>> updateCompOffRequest({
    required int compOffId,
    required String subject,
    required String date,
    required String duration,
    required String reason,
  });
  Future<Either<Failure, String>> uploadCompOffFile({
    required int compOffId,
    required String filePath,
  });
  Future<Either<Failure, String>> updateCompOffRequestStatus({
    required int compOffId,
    required String status,
    String type = 'earn',
  });
  Future<Either<Failure, List<AttendanceRequestComment>>> getComments({
    required int compOffId,
  });
  Future<Either<Failure, String>> addComment({
    required int compOffId,
    required String comment,
  });
}
