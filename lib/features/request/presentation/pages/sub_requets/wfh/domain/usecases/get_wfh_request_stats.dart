import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/wfh_request_stats_model.dart';
import '../repositories/wfh_repository.dart';

class GetWfhRequestStatsParams {
  final int clientId;
  final String requestType;

  const GetWfhRequestStatsParams({
    required this.clientId,
    this.requestType = 'User',
  });
}

class GetWfhRequestStatsUseCase {
  final WfhRepository repository;

  GetWfhRequestStatsUseCase(this.repository);

  Future<Either<Failure, WfhRequestStatsModel>> call(
    GetWfhRequestStatsParams params,
  ) {
    return repository.getWfhRequestStats(
      clientId: params.clientId,
      requestType: params.requestType,
    );
  }
}
