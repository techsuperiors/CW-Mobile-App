import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_document_folders_usecase.dart';
import 'document_folders_state.dart';

class DocumentFoldersCubit extends Cubit<DocumentFoldersState> {
  final GetDocumentFoldersUseCase getDocumentFoldersUseCase;

  DocumentFoldersCubit({required this.getDocumentFoldersUseCase})
    : super(const DocumentFoldersInitial());

  Future<void> loadFolders() async {
    emit(const DocumentFoldersLoading());

    final result = await getDocumentFoldersUseCase();
    result.fold(
      (failure) => emit(DocumentFoldersError(failure.message)),
      (folders) {
        final sharedFolders = folders
            .where((folder) => folder.folderType == 'shared')
            .toList();
        final documentFolders = folders
            .where((folder) => folder.folderType != 'shared')
            .toList();

        emit(
          DocumentFoldersLoaded(
            documentFolders: documentFolders,
            sharedFolders: sharedFolders,
          ),
        );
      },
    );
  }
}
