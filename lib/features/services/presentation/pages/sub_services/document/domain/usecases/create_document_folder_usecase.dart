import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/document_repository.dart';

class CreateDocumentFolderUseCase {
  final DocumentRepository repository;

  CreateDocumentFolderUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String name,
    required List<String> tags,
    String description = '',
  }) {
    return repository.createFolder(
      name: name,
      tags: tags,
      description: description,
    );
  }
}
