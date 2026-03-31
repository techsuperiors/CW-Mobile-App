import 'package:dartz/dartz.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/comp_off_request_model.dart';
import '../repositories/comp_off_repository.dart';

class GetTeamCompOffRequestsParams {
  final int page;
  final int limit;
  final RequestAudienceScope scope;

  const GetTeamCompOffRequestsParams({
    this.page = 1,
    this.limit = 20,
    this.scope = RequestAudienceScope.allUsers,
  });
}

class GetTeamCompOffRequestsUseCase {
  final CompOffRepository repository;

  GetTeamCompOffRequestsUseCase(this.repository);

  Future<Either<Failure, List<CompOffRequestModel>>> call(
    GetTeamCompOffRequestsParams params,
  ) {
    return repository.getTeamCompOffRequests(
      page: params.page,
      limit: params.limit,
      requestType: params.scope.leaveRequestType,
    );
  }
}
