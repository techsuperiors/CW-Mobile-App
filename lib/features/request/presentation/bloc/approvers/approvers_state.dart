import 'package:equatable/equatable.dart';
import '../../pages/sub_requets/leaves/data/models/approver_model.dart';

abstract class ApproversState extends Equatable {
  const ApproversState();

  @override
  List<Object> get props => [];
}

class ApproversInitial extends ApproversState {}

class ApproversLoading extends ApproversState {}

class ApproversLoaded extends ApproversState {
  final List<ApproverLevelModel> approvers;
  final Map<String, dynamic> fullData;

  const ApproversLoaded(this.approvers, this.fullData);

  @override
  List<Object> get props => [approvers, fullData];
}

class ApproversError extends ApproversState {
  final String message;

  const ApproversError(this.message);

  @override
  List<Object> get props => [message];
}
