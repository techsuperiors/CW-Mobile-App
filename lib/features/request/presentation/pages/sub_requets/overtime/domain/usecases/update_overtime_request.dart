import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/overtime_repository.dart';

class UpdateOvertimeRequestUseCase {
  final OvertimeRepository repository;

  UpdateOvertimeRequestUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int requestId,
    required String requestDate,
    required String checkIn,
    required String checkOut,
    required int userId,
    required String description,
  }) {
    return repository.updateOvertimeRequest(
      requestId: requestId,
      requestDate: requestDate,
      checkIn: checkIn,
      checkOut: checkOut,
      userId: userId,
      description: description,
    );
  }
}
