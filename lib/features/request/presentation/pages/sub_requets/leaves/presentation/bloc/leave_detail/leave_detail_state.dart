import 'package:equatable/equatable.dart';
import '../../../data/models/leave_detail_model.dart';

abstract class LeaveDetailState extends Equatable {
  const LeaveDetailState();
  @override
  List<Object?> get props => [];
}

class LeaveDetailInitial extends LeaveDetailState {}

class LeaveDetailLoading extends LeaveDetailState {}

class LeaveDetailLoaded extends LeaveDetailState {
  final LeaveDetailModel detail;
  const LeaveDetailLoaded(this.detail);
  @override
  List<Object?> get props => [detail];
}

class LeaveDetailError extends LeaveDetailState {
  final String message;
  const LeaveDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class LeaveDetailWithdrawing extends LeaveDetailState {
  final LeaveDetailModel detail; // keep detail visible while loading
  const LeaveDetailWithdrawing(this.detail);
  @override
  List<Object?> get props => [detail];
}

class LeaveDetailStatusUpdating extends LeaveDetailState {
  final LeaveDetailModel detail;
  final String status;

  const LeaveDetailStatusUpdating({
    required this.detail,
    required this.status,
  });

  @override
  List<Object?> get props => [detail, status];
}

class LeaveCommentSubmitting extends LeaveDetailState {
  final LeaveDetailModel detail;
  const LeaveCommentSubmitting(this.detail);

  @override
  List<Object?> get props => [detail];
}

class LeaveDetailWithdrawn extends LeaveDetailState {
  final String message;
  const LeaveDetailWithdrawn(this.message);
  @override
  List<Object?> get props => [message];
}

class LeaveStatusUpdated extends LeaveDetailState {
  final String message;

  const LeaveStatusUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class LeaveCommentAdded extends LeaveDetailState {
  final String message;
  const LeaveCommentAdded(this.message);

  @override
  List<Object?> get props => [message];
}
