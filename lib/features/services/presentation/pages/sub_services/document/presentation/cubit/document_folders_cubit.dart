import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_document_folder_usecase.dart';
import '../../domain/usecases/get_document_folders_usecase.dart';
import 'document_folders_state.dart';

class DocumentFoldersCubit extends Cubit<DocumentFoldersState> {
  final GetDocumentFoldersUseCase getDocumentFoldersUseCase;
  final CreateDocumentFolderUseCase createDocumentFolderUseCase;

  DocumentFoldersCubit({
    required this.getDocumentFoldersUseCase,
    required this.createDocumentFolderUseCase,
  })
    : super(const DocumentFoldersInitial());

  Future<void> loadFolders({bool showLoading = true}) async {
    if (showLoading || state is! DocumentFoldersLoaded) {
      emit(const DocumentFoldersLoading());
    }

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

  Future<String?> createFolder({
    required String name,
    required List<String> tags,
    String description = '',
  }) async {
    final result = await createDocumentFolderUseCase(
      name: name,
      tags: tags,
      description: description,
    );
    String? errorMessage;
    await result.fold(
      (failure) async {
        errorMessage = failure.message;
      },
      (_) async {
        await loadFolders(showLoading: false);
      },
    );
    return errorMessage;
  }
}
