import 'package:dartz/dartz.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/wfh_request_model.dart';
import '../repositories/wfh_repository.dart';

class GetTeamWfhRequestsParams {
  final int clientId;
  final int page;
  final int limit;
  final RequestAudienceScope scope;
  final WfhStatus? status;

  const GetTeamWfhRequestsParams({
    required this.clientId,
    this.page = 1,
    this.limit = 50,
    this.scope = RequestAudienceScope.allUsers,
    this.status,
  });
}

class GetTeamWfhRequestsUseCase {
  final WfhRepository repository;

  GetTeamWfhRequestsUseCase(this.repository);

  Future<Either<Failure, List<WfhRequestModel>>> call(
    GetTeamWfhRequestsParams params,
  ) {
    return repository.getTeamWfhRequests(
      clientId: params.clientId,
      page: params.page,
      limit: params.limit,
      scope: params.scope,
      status: params.status,
    );
  }
}
