import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/overtime_request_model.dart';
import '../repositories/overtime_repository.dart';

class GetOvertimeRequestsParams {
  final int clientId;
  final int page;
  final int limit;
  final OvertimeStatus? status;

  const GetOvertimeRequestsParams({
    required this.clientId,
    this.page = 1,
    this.limit = 5,
    this.status,
  });
}

class GetOvertimeRequestsUseCase {
  final OvertimeRepository repository;

  GetOvertimeRequestsUseCase(this.repository);

  Future<Either<Failure, List<OvertimeRequestModel>>> call(
    GetOvertimeRequestsParams params,
  ) {
    return repository.getOvertimeRequests(
      clientId: params.clientId,
      page: params.page,
      limit: params.limit,
      status: params.status,
    );
  }
}
