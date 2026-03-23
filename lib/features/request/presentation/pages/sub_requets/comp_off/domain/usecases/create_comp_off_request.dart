import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/comp_off_repository.dart';

class CreateCompOffRequestUseCase {
  final CompOffRepository repository;

  CreateCompOffRequestUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String type,
    required String date,
    required String duration,
    required String reason,
    required String subject,
    required int requestTo,
    required int userId,
  }) {
    return repository.createCompOffRequest(
      type: type,
      date: date,
      duration: duration,
      reason: reason,
      subject: subject,
      requestTo: requestTo,
      userId: userId,
    );
  }
}
