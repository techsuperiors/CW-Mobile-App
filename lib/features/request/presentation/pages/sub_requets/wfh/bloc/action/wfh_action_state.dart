import 'package:equatable/equatable.dart';

abstract class WfhActionState extends Equatable {
  const WfhActionState();

  @override
  List<Object?> get props => [];
}

class WfhActionInitial extends WfhActionState {
  const WfhActionInitial();
}

class WfhActionInProgress extends WfhActionState {
  const WfhActionInProgress();
}

class WfhActionSuccess extends WfhActionState {
  final String message;

  const WfhActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class WfhActionFailure extends WfhActionState {
  final String errorMessage;

  const WfhActionFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
