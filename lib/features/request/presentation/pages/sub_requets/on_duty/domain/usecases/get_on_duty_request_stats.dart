import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/on_duty_request_stats_model.dart';
import '../repositories/on_duty_repository.dart';

class GetOnDutyRequestStatsParams {
  final int clientId;
  final String requestType;

  const GetOnDutyRequestStatsParams({
    required this.clientId,
    this.requestType = 'User',
  });
}

class GetOnDutyRequestStatsUseCase {
  final OnDutyRepository repository;

  GetOnDutyRequestStatsUseCase(this.repository);

  Future<Either<Failure, OnDutyRequestStatsModel>> call(
    GetOnDutyRequestStatsParams params,
  ) {
    return repository.getOnDutyRequestStats(
      clientId: params.clientId,
      requestType: params.requestType,
    );
  }
}
