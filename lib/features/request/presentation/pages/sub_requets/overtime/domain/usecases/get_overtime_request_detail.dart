import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../entities/overtime_detail.dart';
import '../repositories/overtime_repository.dart';

class GetOvertimeRequestDetailUseCase {
  final OvertimeRepository repository;

  GetOvertimeRequestDetailUseCase(this.repository);

  Future<Either<Failure, OvertimeDetail>> call(int requestId) {
    return repository.getOvertimeRequestDetail(requestId);
  }
}
