import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/wfh_repository.dart';
import '../../models/wfh_request_model.dart';
import '../../models/wfh_requests_page_model.dart';

class GetWfhRequestsParams {
  final int clientId;
  final int page;
  final int limit;
  final WfhStatus? status;

  const GetWfhRequestsParams({
    required this.clientId,
    this.page = 1,
    this.limit = 5,
    this.status,
  });
}

class GetWfhRequestsUseCase {
  final WfhRepository repository;

  GetWfhRequestsUseCase(this.repository);

  Future<Either<Failure, WfhRequestsPageModel>> call(
    GetWfhRequestsParams params,
  ) {
    return repository.getWfhRequests(
      clientId: params.clientId,
      page: params.page,
      limit: params.limit,
      status: params.status,
    );
  }
}
