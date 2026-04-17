import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/document_folder_model.dart';
import '../../domain/usecases/get_document_folder_files_usecase.dart';
import '../../domain/usecases/upload_document_file_usecase.dart';
import 'document_detail_state.dart';

class DocumentDetailCubit extends Cubit<DocumentDetailState> {
  final GetDocumentFolderFilesUseCase getDocumentFolderFilesUseCase;
  final UploadDocumentFileUseCase uploadDocumentFileUseCase;

  DocumentDetailCubit({
    required this.getDocumentFolderFilesUseCase,
    required this.uploadDocumentFileUseCase,
  })
    : super(const DocumentDetailInitial());

  Future<void> loadFolder(
    DocumentFolderModel folder, {
    bool showLoading = true,
  }) async {
    if (showLoading || state is! DocumentDetailLoaded) {
      emit(const DocumentDetailLoading());
    }

    final result = await getDocumentFolderFilesUseCase(folder);
    result.fold(
      (failure) => emit(DocumentDetailError(failure.message)),
      (files) => emit(DocumentDetailLoaded(files: files)),
    );
  }

  Future<String?> uploadFile({
    required DocumentFolderModel folder,
    required String filePath,
  }) async {
    final directoryId = int.tryParse(folder.id);
    if (directoryId == null) {
      return 'Unable to resolve folder id';
    }

    final result = await uploadDocumentFileUseCase(
      directoryId: directoryId,
      filePath: filePath,
    );
    String? errorMessage;
    await result.fold(
      (failure) async {
        errorMessage = failure.message;
      },
      (_) async {
        await loadFolder(folder, showLoading: false);
      },
    );
    return errorMessage;
  }
}
