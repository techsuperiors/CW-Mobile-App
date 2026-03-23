import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../models/wfh_request_model.dart';

abstract class WfhRepository {
  Future<Either<Failure, List<WfhRequestModel>>> getWfhRequests();

  Future<Either<Failure, List<WfhRequestModel>>> getTeamWfhRequests({
    int page = 1,
    int limit = 50,
    String requestType = 'All',
  });

  Future<Either<Failure, void>> updateWfhStatus({
    required int requestId,
    required String status,
  });
}
