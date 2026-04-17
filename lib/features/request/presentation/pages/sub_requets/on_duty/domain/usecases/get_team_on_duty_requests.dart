import 'package:dartz/dartz.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/on_duty_request_model.dart';
import '../repositories/on_duty_repository.dart';

class GetTeamOnDutyRequestsParams {
  final int clientId;
  final int page;
  final int limit;
  final RequestAudienceScope scope;
  final OnDutyStatus? status;

  const GetTeamOnDutyRequestsParams({
    required this.clientId,
    this.page = 1,
    this.limit = 50,
    this.scope = RequestAudienceScope.allUsers,
    this.status,
  });
}

class GetTeamOnDutyRequestsUseCase {
  final OnDutyRepository repository;

  GetTeamOnDutyRequestsUseCase(this.repository);

  Future<Either<Failure, List<OnDutyRequestModel>>> call(
    GetTeamOnDutyRequestsParams params,
  ) {
    return repository.getTeamOnDutyRequests(
      clientId: params.clientId,
      page: params.page,
      limit: params.limit,
      requestType: params.scope.attendanceRequestType,
      status: params.status,
    );
  }
}
