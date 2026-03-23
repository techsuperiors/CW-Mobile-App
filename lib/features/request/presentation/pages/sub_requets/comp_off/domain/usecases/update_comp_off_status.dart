import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/comp_off_repository.dart';

class UpdateCompOffStatusUseCase {
  final CompOffRepository repository;

  UpdateCompOffStatusUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int compOffId,
    required String status,
    String type = 'earn',
  }) {
    return repository.updateCompOffRequestStatus(
      compOffId: compOffId,
      status: status,
      type: type,
    );
  }
}
