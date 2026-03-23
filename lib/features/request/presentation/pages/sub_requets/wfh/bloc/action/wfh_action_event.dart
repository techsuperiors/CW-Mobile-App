import 'package:equatable/equatable.dart';

abstract class WfhActionEvent extends Equatable {
  const WfhActionEvent();

  @override
  List<Object?> get props => [];
}

class UpdateWfhStatus extends WfhActionEvent {
  final int requestId;
  final String status;

  const UpdateWfhStatus({
    required this.requestId,
    required this.status,
  });

  @override
  List<Object?> get props => [requestId, status];
}
