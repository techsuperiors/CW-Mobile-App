import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../repositories/agreement_repository.dart';

/// Use case for submitting agreement consent
class SubmitAgreementConsentUseCase {
  final AgreementRepository repository;

  SubmitAgreementConsentUseCase(this.repository);

  Future<Either<Failure, AgreementConsentResult>> call(
    int agreementId,
    bool agreementAcknowledged,
    String signatureFilePath,
  ) {
    return repository.submitAgreementConsent(
      agreementId,
      agreementAcknowledged,
      signatureFilePath,
    );
  }
}
