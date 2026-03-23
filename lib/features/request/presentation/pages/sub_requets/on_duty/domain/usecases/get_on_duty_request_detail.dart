import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../domain/entities/on_duty_detail.dart';
import '../repositories/on_duty_repository.dart';

class GetOnDutyRequestDetailUseCase {
  final OnDutyRepository repository;

  GetOnDutyRequestDetailUseCase(this.repository);

  Future<Either<Failure, OnDutyDetail>> call(int requestId) {
    return repository.getOnDutyRequestDetail(requestId);
  }
}
