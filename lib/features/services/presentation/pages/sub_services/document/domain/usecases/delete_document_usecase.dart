import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/document_repository.dart';

class DeleteDocumentUseCase {
  final DocumentRepository repository;

  DeleteDocumentUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required int directoryId,
    required int documentId,
  }) {
    return repository.deleteDocument(
      directoryId: directoryId,
      documentId: documentId,
    );
  }
}
