import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../../core/usecase/usecase.dart';
import '../../models/wfh_request_model.dart';
import '../repositories/wfh_repository.dart';

class GetWfhRequestsUseCase implements UseCaseNoParams<List<WfhRequestModel>> {
  final WfhRepository repository;

  GetWfhRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<WfhRequestModel>>> call() {
    return repository.getWfhRequests();
  }
}
