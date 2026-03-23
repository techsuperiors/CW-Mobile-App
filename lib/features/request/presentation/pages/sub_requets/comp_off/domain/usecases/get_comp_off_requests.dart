import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../models/comp_off_request_model.dart';
import '../repositories/comp_off_repository.dart';

class GetCompOffRequestsUseCase {
  final CompOffRepository repository;

  GetCompOffRequestsUseCase(this.repository);

  Future<Either<Failure, List<CompOffRequestModel>>> call() {
    return repository.getCompOffRequests();
  }
}
