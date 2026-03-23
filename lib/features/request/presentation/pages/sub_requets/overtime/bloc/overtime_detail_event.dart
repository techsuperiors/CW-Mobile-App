import 'package:equatable/equatable.dart';

abstract class OvertimeDetailEvent extends Equatable {
  const OvertimeDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadOvertimeDetail extends OvertimeDetailEvent {
  final int requestId;
  final int clientId;

  const LoadOvertimeDetail({required this.requestId, required this.clientId});

  @override
  List<Object?> get props => [requestId, clientId];
}

class UpdateOvertimeRequestStatus extends OvertimeDetailEvent {
  final int requestId;
  final int clientId;
  final String status;

  const UpdateOvertimeRequestStatus({
    required this.requestId,
    required this.clientId,
    required this.status,
  });

  @override
  List<Object?> get props => [requestId, clientId, status];
}

class AddOvertimeComment extends OvertimeDetailEvent {
  final int requestId;
  final int clientId;
  final String comment;

  const AddOvertimeComment({
    required this.requestId,
    required this.clientId,
    required this.comment,
  });

  @override
  List<Object?> get props => [requestId, clientId, comment];
}
