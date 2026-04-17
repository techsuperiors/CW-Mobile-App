import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/document_repository.dart';

class UploadDocumentFileUseCase {
  final DocumentRepository repository;

  UploadDocumentFileUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int directoryId,
    required String filePath,
  }) {
    return repository.uploadFile(
      directoryId: directoryId,
      filePath: filePath,
    );
  }
}
