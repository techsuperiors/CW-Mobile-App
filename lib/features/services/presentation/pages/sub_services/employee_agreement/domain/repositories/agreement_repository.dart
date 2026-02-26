import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../entities/agreement.dart';

/// Agreement Consent Result Entity
class AgreementConsentResult {
  final bool success;
  final String? message;

  AgreementConsentResult({
    required this.success,
    this.message,
  });
}

/// Agreement repository interface
abstract class AgreementRepository {
  Future<Either<Failure, AgreementList>> getAgreementList(int userId);
  Future<Either<Failure, AgreementConsentResult>> submitAgreementConsent(
    int agreementId,
    bool agreementAcknowledged,
    String signatureFilePath,
  );
}
