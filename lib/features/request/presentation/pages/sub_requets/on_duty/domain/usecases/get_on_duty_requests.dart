import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../../core/usecase/usecase.dart';
import '../../models/on_duty_request_model.dart';
import '../repositories/on_duty_repository.dart';

class GetOnDutyRequestsUseCase
    implements UseCaseNoParams<List<OnDutyRequestModel>> {
  final OnDutyRepository repository;

  GetOnDutyRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<OnDutyRequestModel>>> call() {
    return repository.getOnDutyRequests();
  }
}
