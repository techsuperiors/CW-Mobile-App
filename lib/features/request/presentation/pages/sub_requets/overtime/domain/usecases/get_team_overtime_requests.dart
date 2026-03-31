import 'package:dartz/dartz.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/overtime_request_model.dart';
import '../repositories/overtime_repository.dart';

class GetTeamOvertimeRequestsParams {
  final int page;
  final int limit;
  final RequestAudienceScope scope;

  const GetTeamOvertimeRequestsParams({
    this.page = 1,
    this.limit = 20,
    this.scope = RequestAudienceScope.allUsers,
  });
}

class GetTeamOvertimeRequestsUseCase {
  final OvertimeRepository repository;

  GetTeamOvertimeRequestsUseCase(this.repository);

  Future<Either<Failure, List<OvertimeRequestModel>>> call(
    GetTeamOvertimeRequestsParams params,
  ) {
    return repository.getTeamOvertimeRequests(
      page: params.page,
      limit: params.limit,
      requestType: params.scope.attendanceRequestType,
    );
  }
}
