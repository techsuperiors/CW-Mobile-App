import 'package:equatable/equatable.dart';

abstract class ApplyOvertimeState extends Equatable {
  const ApplyOvertimeState();

  @override
  List<Object?> get props => [];
}

class ApplyOvertimeInitial extends ApplyOvertimeState {
  const ApplyOvertimeInitial();
}

class ApplyOvertimeSubmitting extends ApplyOvertimeState {
  const ApplyOvertimeSubmitting();
}

class ApplyOvertimeSuccess extends ApplyOvertimeState {
  final String message;

  const ApplyOvertimeSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ApplyOvertimeError extends ApplyOvertimeState {
  final String message;

  const ApplyOvertimeError(this.message);

  @override
  List<Object?> get props => [message];
}
