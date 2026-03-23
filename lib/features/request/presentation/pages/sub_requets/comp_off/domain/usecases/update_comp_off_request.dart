import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/comp_off_repository.dart';

class UpdateCompOffRequestUseCase {
  final CompOffRepository repository;

  UpdateCompOffRequestUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int compOffId,
    required String subject,
    required String date,
    required String duration,
    required String reason,
  }) {
    return repository.updateCompOffRequest(
      compOffId: compOffId,
      subject: subject,
      date: date,
      duration: duration,
      reason: reason,
    );
  }
}
