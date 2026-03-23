import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/overtime_repository.dart';

class CreateOvertimeRequestUseCase {
  final OvertimeRepository repository;

  CreateOvertimeRequestUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String requestDate,
    required String checkIn,
    required String checkOut,
    required String subject,
    required String description,
    required int userId,
  }) {
    return repository.createOvertimeRequest(
      requestDate: requestDate,
      checkIn: checkIn,
      checkOut: checkOut,
      subject: subject,
      description: description,
      userId: userId,
    );
  }
}
