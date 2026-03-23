import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/on_duty_request_model.dart';
import '../repositories/on_duty_repository.dart';

class GetTeamOnDutyRequestsParams {
  final int page;
  final int limit;
  final String requestType;

  const GetTeamOnDutyRequestsParams({
    this.page = 1,
    this.limit = 50,
    this.requestType = 'All',
  });
}

class GetTeamOnDutyRequestsUseCase {
  final OnDutyRepository repository;

  GetTeamOnDutyRequestsUseCase(this.repository);

  Future<Either<Failure, List<OnDutyRequestModel>>> call(
    GetTeamOnDutyRequestsParams params,
  ) {
    return repository.getTeamOnDutyRequests(
      page: params.page,
      limit: params.limit,
      requestType: params.requestType,
    );
  }
}
