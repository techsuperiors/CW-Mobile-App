import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/overtime_request_stats_model.dart';
import '../repositories/overtime_repository.dart';

class GetOvertimeRequestStatsParams {
  final int clientId;
  final String requestType;

  const GetOvertimeRequestStatsParams({
    required this.clientId,
    this.requestType = 'User',
  });
}

class GetOvertimeRequestStatsUseCase {
  final OvertimeRepository repository;

  GetOvertimeRequestStatsUseCase(this.repository);

  Future<Either<Failure, OvertimeRequestStatsModel>> call(
    GetOvertimeRequestStatsParams params,
  ) {
    return repository.getOvertimeRequestStats(
      clientId: params.clientId,
      requestType: params.requestType,
    );
  }
}
