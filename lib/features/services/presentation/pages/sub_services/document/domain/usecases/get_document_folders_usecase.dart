import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../models/document_folder_model.dart';
import '../repositories/document_repository.dart';

class GetDocumentFoldersUseCase {
  final DocumentRepository repository;

  GetDocumentFoldersUseCase(this.repository);

  Future<Either<Failure, List<DocumentFolderModel>>> call() {
    return repository.getFolders();
  }
}
