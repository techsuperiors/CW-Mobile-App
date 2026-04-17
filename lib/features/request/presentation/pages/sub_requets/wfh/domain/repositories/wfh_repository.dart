import 'package:dartz/dartz.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../models/wfh_request_model.dart';
import '../../models/wfh_request_stats_model.dart';
import '../../models/wfh_requests_page_model.dart';

abstract class WfhRepository {
  Future<Either<Failure, WfhRequestsPageModel>> getWfhRequests({
    required int clientId,
    int page = 1,
    int limit = 5,
    WfhStatus? status,
  });
  Future<Either<Failure, WfhRequestStatsModel>> getWfhRequestStats({
    required int clientId,
    String requestType = 'User',
  });

  Future<Either<Failure, List<WfhRequestModel>>> getTeamWfhRequests({
    required int clientId,
    int page = 1,
    int limit = 50,
    RequestAudienceScope scope = RequestAudienceScope.allUsers,
    WfhStatus? status,
  });

  Future<Either<Failure, void>> updateWfhStatus({
    required int requestId,
    required String status,
  });
}
