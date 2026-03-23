import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/on_duty_repository.dart';

class UpdateOnDutyRequestStatusUseCase {
  final OnDutyRepository repository;

  UpdateOnDutyRequestStatusUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int requestId,
    required String status,
  }) {
    return repository.updateOnDutyRequestStatus(
      requestId: requestId,
      status: status,
    );
  }
}
