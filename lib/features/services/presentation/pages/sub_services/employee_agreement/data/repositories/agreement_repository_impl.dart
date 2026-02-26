import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../domain/entities/agreement.dart';
import '../../domain/repositories/agreement_repository.dart';
import '../datasources/agreement_remote_datasource.dart';
import '../models/agreement_model.dart';

/// Agreement repository implementation
class AgreementRepositoryImpl implements AgreementRepository {
  final AgreementRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AgreementRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AgreementList>> getAgreementList(int userId) async {
    if (await networkInfo.isConnected) {
      try {
        final responseModels = await remoteDataSource.getAgreementList(userId);
        
        // Convert models to entities
        final agreements = responseModels.map((model) {
          return Agreement(
            id: model.id,
            clientId: model.clientId,
            userId: model.userId,
            category: model.category,
            agreementName: model.agreementName,
            documentId: model.documentId,
            agreementContent: model.agreementContent,
            signatureRequired: model.signatureRequired,
            acknowledgementRequired: model.acknowledgementRequired,
            agreementAcknowledged: model.agreementAcknowledged,
            expiryDate: model.expiryDate,
            signatureUrl: model.signatureUrl,
            documentUrl: model.documentUrl,
            agreementStatus: model.agreementStatus,
            status: model.status,
            sentAt: model.sentAt,
            signedAt: model.signedAt,
            createdAt: model.createdAt,
            createdBy: model.createdBy,
            updatedAt: model.updatedAt,
            updatedBy: model.updatedBy,
            agreementAssignedTo: AgreementUser(
              id: model.agreementAssignedTo.id,
              email: model.agreementAssignedTo.email,
              firstName: model.agreementAssignedTo.firstName,
              lastName: model.agreementAssignedTo.lastName,
              imageUrl: model.agreementAssignedTo.imageUrl,
              profileColor: model.agreementAssignedTo.profileColor,
            ),
            agreementAssignedBy: AgreementUser(
              id: model.agreementAssignedBy.id,
              email: model.agreementAssignedBy.email,
              firstName: model.agreementAssignedBy.firstName,
              lastName: model.agreementAssignedBy.lastName,
              imageUrl: model.agreementAssignedBy.imageUrl,
              profileColor: model.agreementAssignedBy.profileColor,
            ),
          );
        }).toList();
        
        return Right(AgreementList(agreements: agreements));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, AgreementConsentResult>> submitAgreementConsent(
    int agreementId,
    bool agreementAcknowledged,
    String signatureFilePath,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final request = AgreementConsentRequest(
          agreementId: agreementId,
          agreementAcknowledged: agreementAcknowledged,
        );

        final response = await remoteDataSource.submitAgreementConsent(
          request,
          signatureFilePath,
        );

        return Right(
          AgreementConsentResult(
            success: response.success,
            message: response.message,
          ),
        );
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }
}
