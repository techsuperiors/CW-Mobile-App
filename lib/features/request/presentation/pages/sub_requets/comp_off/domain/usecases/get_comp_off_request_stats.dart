import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/comp_off_request_stats_model.dart';
import '../repositories/comp_off_repository.dart';

class GetCompOffRequestStatsParams {
  final int userId;

  const GetCompOffRequestStatsParams({required this.userId});
}

class GetCompOffRequestStatsUseCase {
  final CompOffRepository repository;

  GetCompOffRequestStatsUseCase(this.repository);

  Future<Either<Failure, CompOffRequestStatsModel>> call(
    GetCompOffRequestStatsParams params,
  ) {
    return repository.getCompOffRequestStats(userId: params.userId);
  }
}
