import 'package:equatable/equatable.dart';

abstract class ApplyCompOffState extends Equatable {
  const ApplyCompOffState();
  @override
  List<Object?> get props => [];
}

class ApplyCompOffInitial extends ApplyCompOffState {
  const ApplyCompOffInitial();
}

class ApplyCompOffSubmitting extends ApplyCompOffState {
  const ApplyCompOffSubmitting();
}

class ApplyCompOffSuccess extends ApplyCompOffState {
  final String message;
  const ApplyCompOffSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class ApplyCompOffError extends ApplyCompOffState {
  final String message;
  const ApplyCompOffError(this.message);
  @override
  List<Object?> get props => [message];
}
