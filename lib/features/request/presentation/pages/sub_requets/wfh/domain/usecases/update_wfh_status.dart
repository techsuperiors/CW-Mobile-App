import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/wfh_repository.dart';

class UpdateWfhStatusUseCase {
  final WfhRepository repository;

  UpdateWfhStatusUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required int requestId,
    required String status,
  }) {
    return repository.updateWfhStatus(
      requestId: requestId,
      status: status,
    );
  }
}
