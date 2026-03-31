import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/wfh_repository.dart';
import '../../models/wfh_requests_page_model.dart';

class GetWfhRequestsParams {
  final int page;
  final int limit;

  const GetWfhRequestsParams({
    this.page = 1,
    this.limit = 5,
  });
}

class GetWfhRequestsUseCase {
  final WfhRepository repository;

  GetWfhRequestsUseCase(this.repository);

  Future<Either<Failure, WfhRequestsPageModel>> call(
    GetWfhRequestsParams params,
  ) {
    return repository.getWfhRequests(page: params.page, limit: params.limit);
  }
}
