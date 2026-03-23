import 'package:equatable/equatable.dart';

class OnDutyDetailEvent extends Equatable {
  const OnDutyDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadOnDutyDetail extends OnDutyDetailEvent {
  final int requestId;
  final int clientId;

  const LoadOnDutyDetail({
    required this.requestId,
    required this.clientId,
  });

  @override
  List<Object?> get props => [requestId, clientId];
}

class UpdateOnDutyRequestStatus extends OnDutyDetailEvent {
  final int requestId;
  final int clientId;
  final String status;

  const UpdateOnDutyRequestStatus({
    required this.requestId,
    required this.clientId,
    required this.status,
  });

  @override
  List<Object?> get props => [requestId, clientId, status];
}

class AddOnDutyComment extends OnDutyDetailEvent {
  final int requestId;
  final int clientId;
  final String comment;

  const AddOnDutyComment({
    required this.requestId,
    required this.clientId,
    required this.comment,
  });

  @override
  List<Object?> get props => [requestId, clientId, comment];
}
