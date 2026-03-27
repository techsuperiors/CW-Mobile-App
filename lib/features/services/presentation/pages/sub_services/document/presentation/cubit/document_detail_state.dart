import 'package:equatable/equatable.dart';

import '../../domain/models/document_file_model.dart';

abstract class DocumentDetailState extends Equatable {
  const DocumentDetailState();

  @override
  List<Object?> get props => [];
}

class DocumentDetailInitial extends DocumentDetailState {
  const DocumentDetailInitial();
}

class DocumentDetailLoading extends DocumentDetailState {
  const DocumentDetailLoading();
}

class DocumentDetailLoaded extends DocumentDetailState {
  final List<DocumentFileModel> files;

  const DocumentDetailLoaded({required this.files});

  @override
  List<Object?> get props => [files];
}

class DocumentDetailError extends DocumentDetailState {
  final String message;

  const DocumentDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
