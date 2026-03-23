import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/overtime_repository.dart';

class WithdrawOvertimeRequestUseCase {
  final OvertimeRepository repository;

  WithdrawOvertimeRequestUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int requestId,
    String status = 'Withdrawn',
  }) {
    return repository.withdrawOvertimeRequest(
      requestId: requestId,
      status: status,
    );
  }
}
