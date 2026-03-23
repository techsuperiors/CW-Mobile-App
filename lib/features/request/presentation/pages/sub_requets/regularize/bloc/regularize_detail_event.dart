import 'package:equatable/equatable.dart';

class RegularizeDetailEvent extends Equatable {
  const RegularizeDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadRegularizeDetail extends RegularizeDetailEvent {
  final int requestId;
  final int clientId;

  const LoadRegularizeDetail({
    required this.requestId,
    required this.clientId,
  });

  @override
  List<Object?> get props => [requestId, clientId];
}

class UpdateRegularizeRequestStatus extends RegularizeDetailEvent {
  final int requestId;
  final int clientId;
  final String status;

  const UpdateRegularizeRequestStatus({
    required this.requestId,
    required this.clientId,
    required this.status,
  });

  @override
  List<Object?> get props => [requestId, clientId, status];
}

class AddRegularizeComment extends RegularizeDetailEvent {
  final int requestId;
  final int clientId;
  final String comment;

  const AddRegularizeComment({
    required this.requestId,
    required this.clientId,
    required this.comment,
  });

  @override
  List<Object?> get props => [requestId, clientId, comment];
}
