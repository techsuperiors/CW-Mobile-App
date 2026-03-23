import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../entities/comp_off_detail.dart';
import '../repositories/comp_off_repository.dart';

class GetCompOffDetailUseCase {
  final CompOffRepository repository;

  GetCompOffDetailUseCase(this.repository);

  Future<Either<Failure, CompOffDetail>> call(int compOffId) {
    return repository.getCompOffDetail(compOffId);
  }
}
