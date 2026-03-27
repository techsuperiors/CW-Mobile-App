import 'package:dartz/dartz.dart';

import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../domain/models/document_file_model.dart';
import '../../domain/models/document_folder_model.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_remote_datasource.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DocumentRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<DocumentFolderModel>>> getFolders() async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final folders = await remoteDataSource.getUserDirectories();
      return Right(folders.map((folder) => folder.toDomain()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, List<DocumentFileModel>>> getFolderFiles(
    DocumentFolderModel folder,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      if (_isEmployeeAgreementsFolder(folder)) {
        final agreements =
            await remoteDataSource.getEmployeeAgreementDocuments();
        return Right(
          agreements.map((agreement) => agreement.toDomain(folder.id)).toList(),
        );
      }

      final details = await remoteDataSource.getDirectoryDetails(
        int.tryParse(folder.id) ?? 0,
      );
      return Right(
        details.documents.map((document) => document.toDomain(folder.id)).toList(),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDocument({
    required int directoryId,
    required int documentId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      await remoteDataSource.deleteDocument(
        directoryId: directoryId,
        documentId: documentId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  bool _isEmployeeAgreementsFolder(DocumentFolderModel folder) {
    final normalized = folder.name.trim().toLowerCase();
    return normalized == 'employee agreements' ||
        normalized.contains('employee agree');
  }
}
