import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/on_duty_request_model.dart';
import '../repositories/on_duty_repository.dart';

class GetOnDutyRequestsParams {
  final int clientId;
  final int page;
  final int limit;
  final OnDutyStatus? status;

  const GetOnDutyRequestsParams({
    required this.clientId,
    this.page = 1,
    this.limit = 5,
    this.status,
  });
}

class GetOnDutyRequestsUseCase {
  final OnDutyRepository repository;

  GetOnDutyRequestsUseCase(this.repository);

  Future<Either<Failure, List<OnDutyRequestModel>>> call(
    GetOnDutyRequestsParams params,
  ) {
    return repository.getOnDutyRequests(
      clientId: params.clientId,
      page: params.page,
      limit: params.limit,
      status: params.status,
    );
  }
}
