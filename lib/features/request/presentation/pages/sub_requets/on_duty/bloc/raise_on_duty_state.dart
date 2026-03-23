import 'package:equatable/equatable.dart';

abstract class RaiseOnDutyRequestState extends Equatable {
  const RaiseOnDutyRequestState();

  @override
  List<Object> get props => [];
}

class RaiseOnDutyRequestInitial extends RaiseOnDutyRequestState {
  const RaiseOnDutyRequestInitial();
}

class RaiseOnDutyRequestSubmitting extends RaiseOnDutyRequestState {
  const RaiseOnDutyRequestSubmitting();
}

class RaiseOnDutyRequestSuccess extends RaiseOnDutyRequestState {
  final String message;

  const RaiseOnDutyRequestSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class RaiseOnDutyRequestFailure extends RaiseOnDutyRequestState {
  final String message;

  const RaiseOnDutyRequestFailure(this.message);

  @override
  List<Object> get props => [message];
}
