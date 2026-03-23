import 'package:equatable/equatable.dart';
import '../../../domain/entities/leave_history_entity.dart';

abstract class LeaveHistoryState extends Equatable {
  const LeaveHistoryState();

  @override
  List<Object?> get props => [];
}

class LeaveHistoryInitial extends LeaveHistoryState {}

class LeaveHistoryLoading extends LeaveHistoryState {}

class LeaveHistoryLoaded extends LeaveHistoryState {
  final List<LeaveHistoryEntity> history;

  const LeaveHistoryLoaded({required this.history});

  @override
  List<Object?> get props => [history];
}

class LeaveHistoryError extends LeaveHistoryState {
  final String message;

  const LeaveHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
