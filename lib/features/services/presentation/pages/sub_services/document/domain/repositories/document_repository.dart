import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../models/document_file_model.dart';
import '../models/document_folder_model.dart';

abstract class DocumentRepository {
  Future<Either<Failure, List<DocumentFolderModel>>> getFolders();
  Future<Either<Failure, String>> createFolder({
    required String name,
    required List<String> tags,
    String description = '',
  });
  Future<Either<Failure, List<DocumentFileModel>>> getFolderFiles(
    DocumentFolderModel folder,
  );
  Future<Either<Failure, String>> uploadFile({
    required int directoryId,
    required String filePath,
  });
  Future<Either<Failure, void>> deleteDocument({
    required int directoryId,
    required int documentId,
  });
}
