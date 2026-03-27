import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../models/document_file_model.dart';
import '../models/document_folder_model.dart';
import '../repositories/document_repository.dart';

class GetDocumentFolderFilesUseCase {
  final DocumentRepository repository;

  GetDocumentFolderFilesUseCase(this.repository);

  Future<Either<Failure, List<DocumentFileModel>>> call(
    DocumentFolderModel folder,
  ) {
    return repository.getFolderFiles(folder);
  }
}
