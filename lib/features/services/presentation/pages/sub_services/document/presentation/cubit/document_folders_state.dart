import 'package:equatable/equatable.dart';

import '../../domain/models/document_folder_model.dart';

abstract class DocumentFoldersState extends Equatable {
  const DocumentFoldersState();

  @override
  List<Object?> get props => [];
}

class DocumentFoldersInitial extends DocumentFoldersState {
  const DocumentFoldersInitial();
}

class DocumentFoldersLoading extends DocumentFoldersState {
  const DocumentFoldersLoading();
}

class DocumentFoldersLoaded extends DocumentFoldersState {
  final List<DocumentFolderModel> documentFolders;
  final List<DocumentFolderModel> sharedFolders;

  const DocumentFoldersLoaded({
    required this.documentFolders,
    required this.sharedFolders,
  });

  @override
  List<Object?> get props => [documentFolders, sharedFolders];
}

class DocumentFoldersError extends DocumentFoldersState {
  final String message;

  const DocumentFoldersError(this.message);

  @override
  List<Object?> get props => [message];
}
