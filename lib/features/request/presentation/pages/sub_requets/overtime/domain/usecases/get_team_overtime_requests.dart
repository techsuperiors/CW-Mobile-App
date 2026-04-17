import 'package:dartz/dartz.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/overtime_request_model.dart';
import '../repositories/overtime_repository.dart';

class GetTeamOvertimeRequestsParams {
  final int clientId;
  final int page;
  final int limit;
  final RequestAudienceScope scope;
  final OvertimeStatus? status;

  const GetTeamOvertimeRequestsParams({
    required this.clientId,
    this.page = 1,
    this.limit = 20,
    this.scope = RequestAudienceScope.allUsers,
    this.status,
  });
}

class GetTeamOvertimeRequestsUseCase {
  final OvertimeRepository repository;

  GetTeamOvertimeRequestsUseCase(this.repository);

  Future<Either<Failure, List<OvertimeRequestModel>>> call(
    GetTeamOvertimeRequestsParams params,
  ) {
    return repository.getTeamOvertimeRequests(
      clientId: params.clientId,
      page: params.page,
      limit: params.limit,
      requestType: params.scope.attendanceRequestType,
      status: params.status,
    );
  }
}
