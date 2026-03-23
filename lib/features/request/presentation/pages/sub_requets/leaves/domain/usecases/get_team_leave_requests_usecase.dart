import 'package:collectivWork/core/error/failures.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/domain/entities/leave_entity.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/domain/repositories/leaves_repository.dart';
import 'package:dartz/dartz.dart';

class GetTeamLeaveRequestsParams {
  final int clientId;
  final int page;
  final int limit;

  const GetTeamLeaveRequestsParams({
    required this.clientId,
    this.page = 1,
    this.limit = 50,
  });
}

class GetTeamLeaveRequestsUseCase {
  final LeavesRepository repository;

  const GetTeamLeaveRequestsUseCase(this.repository);

  Future<Either<Failure, List<LeaveEntity>>> call(
    GetTeamLeaveRequestsParams params,
  ) {
    return repository.getTeamLeaveRequests(
      clientId: params.clientId,
      page: params.page,
      limit: params.limit,
    );
  }
}
