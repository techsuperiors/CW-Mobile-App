import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../entities/agreement.dart';
import '../repositories/agreement_repository.dart';

/// Use case for getting agreement list
class GetAgreementListUseCase {
  final AgreementRepository repository;

  GetAgreementListUseCase(this.repository);

  Future<Either<Failure, AgreementList>> call(int userId) {
    return repository.getAgreementList(userId);
  }
}
