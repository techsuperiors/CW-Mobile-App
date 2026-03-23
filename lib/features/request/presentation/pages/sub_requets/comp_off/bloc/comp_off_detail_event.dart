import 'package:equatable/equatable.dart';

abstract class CompOffDetailEvent extends Equatable {
  const CompOffDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadCompOffDetail extends CompOffDetailEvent {
  final int compOffId;
  const LoadCompOffDetail(this.compOffId);
  @override
  List<Object?> get props => [compOffId];
}

class AddCompOffCommentEvent extends CompOffDetailEvent {
  final int compOffId;
  final String comment;
  const AddCompOffCommentEvent({required this.compOffId, required this.comment});
  @override
  List<Object?> get props => [compOffId, comment];
}

class UploadCompOffFileEvent extends CompOffDetailEvent {
  final int compOffId;
  final String filePath;
  const UploadCompOffFileEvent({required this.compOffId, required this.filePath});
  @override
  List<Object?> get props => [compOffId, filePath];
}

class UpdateCompOffRequestStatus extends CompOffDetailEvent {
  final int compOffId;
  final String status;
  final String type;

  const UpdateCompOffRequestStatus({
    required this.compOffId,
    required this.status,
    this.type = 'earn',
  });

  @override
  List<Object?> get props => [compOffId, status, type];
}
