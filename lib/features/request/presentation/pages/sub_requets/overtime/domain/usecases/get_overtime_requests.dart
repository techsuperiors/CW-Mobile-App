import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/overtime_request_model.dart';
import '../repositories/overtime_repository.dart';

class GetOvertimeRequestsUseCase {
  final OvertimeRepository repository;

  GetOvertimeRequestsUseCase(this.repository);

  Future<Either<Failure, List<OvertimeRequestModel>>> call({
    int page = 1,
    int limit = 20,
  }) {
    return repository.getOvertimeRequests(page: page, limit: limit);
  }
}
