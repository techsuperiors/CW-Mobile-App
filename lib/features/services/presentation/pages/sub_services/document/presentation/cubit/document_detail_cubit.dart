import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/document_folder_model.dart';
import '../../domain/usecases/get_document_folder_files_usecase.dart';
import 'document_detail_state.dart';

class DocumentDetailCubit extends Cubit<DocumentDetailState> {
  final GetDocumentFolderFilesUseCase getDocumentFolderFilesUseCase;

  DocumentDetailCubit({required this.getDocumentFolderFilesUseCase})
    : super(const DocumentDetailInitial());

  Future<void> loadFolder(DocumentFolderModel folder) async {
    emit(const DocumentDetailLoading());

    final result = await getDocumentFolderFilesUseCase(folder);
    result.fold(
      (failure) => emit(DocumentDetailError(failure.message)),
      (files) => emit(DocumentDetailLoaded(files: files)),
    );
  }
}
