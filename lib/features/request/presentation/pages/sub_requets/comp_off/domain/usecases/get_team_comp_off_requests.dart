import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/comp_off_request_model.dart';
import '../repositories/comp_off_repository.dart';

class GetTeamCompOffRequestsUseCase {
  final CompOffRepository repository;

  GetTeamCompOffRequestsUseCase(this.repository);

  Future<Either<Failure, List<CompOffRequestModel>>> call({
    int page = 1,
    int limit = 20,
    String requestType = 'All',
  }) {
    return repository.getTeamCompOffRequests(
      page: page,
      limit: limit,
      requestType: requestType,
    );
  }
}
