import 'package:collectivWork/core/error/failures.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/domain/entities/leave_entity.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/domain/entities/team_leave_requests_page_entity.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/domain/repositories/leaves_repository.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import 'package:dartz/dartz.dart';

class GetTeamLeaveRequestsParams {
  final int clientId;
  final RequestAudienceScope scope;
  final LeaveStatus? status;
  final int page;
  final int limit;

  const GetTeamLeaveRequestsParams({
    required this.clientId,
    this.scope = RequestAudienceScope.allUsers,
    this.status,
    this.page = 1,
    this.limit = 50,
  });
}

class GetTeamLeaveRequestsUseCase {
  final LeavesRepository repository;

  const GetTeamLeaveRequestsUseCase(this.repository);

  Future<Either<Failure, TeamLeaveRequestsPageEntity>> call(
    GetTeamLeaveRequestsParams params,
  ) {
    return repository.getTeamLeaveRequests(
      clientId: params.clientId,
      scope: params.scope,
      status: params.status,
      page: params.page,
      limit: params.limit,
    );
  }
}
