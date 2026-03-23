import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/overtime_request_model.dart';
import '../repositories/overtime_repository.dart';

class GetTeamOvertimeRequestsParams {
  final int page;
  final int limit;
  final String requestType;

  const GetTeamOvertimeRequestsParams({
    this.page = 1,
    this.limit = 20,
    this.requestType = 'All',
  });
}

class GetTeamOvertimeRequestsUseCase {
  final OvertimeRepository repository;

  GetTeamOvertimeRequestsUseCase(this.repository);

  Future<Either<Failure, List<OvertimeRequestModel>>> call({
    int page = 1,
    int limit = 20,
    String requestType = 'All',
  }) {
    return repository.getTeamOvertimeRequests(
      page: page,
      limit: limit,
      requestType: requestType,
    );
  }
}
