import 'package:equatable/equatable.dart';

import '../../domain/models/visit_model.dart';

abstract class VisitEvent extends Equatable {
  const VisitEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyVisits extends VisitEvent {
  final bool forceRefresh;

  const LoadMyVisits({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadTeamVisits extends VisitEvent {
  final bool forceRefresh;

  const LoadTeamVisits({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadVisitEmployees extends VisitEvent {
  final bool forceRefresh;

  const LoadVisitEmployees({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadVisitCustomers extends VisitEvent {
  final bool forceRefresh;

  const LoadVisitCustomers({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadVisitAddresses extends VisitEvent {
  final bool forceRefresh;

  const LoadVisitAddresses({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class CreateVisitRequested extends VisitEvent {
  final CreateVisitParams params;

  const CreateVisitRequested(this.params);

  @override
  List<Object?> get props => [params];
}

class CreateVisitActivityRequested extends VisitEvent {
  final CreateVisitActivityParams params;

  const CreateVisitActivityRequested(this.params);

  @override
  List<Object?> get props => [params];
}

class UpdateVisitActivityRequested extends VisitEvent {
  final UpdateVisitActivityParams params;

  const UpdateVisitActivityRequested(this.params);

  @override
  List<Object?> get props => [params];
}

class StartVisitActivityRequested extends VisitEvent {
  final StartVisitActivityParams params;

  const StartVisitActivityRequested(this.params);

  @override
  List<Object?> get props => [params];
}

class CompleteVisitActivityRequested extends VisitEvent {
  final CompleteVisitActivityParams params;

  const CompleteVisitActivityRequested(this.params);

  @override
  List<Object?> get props => [params];
}

class DeleteVisitActivityRequested extends VisitEvent {
  final int activityId;

  const DeleteVisitActivityRequested(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class LoadVisitActivityDetails extends VisitEvent {
  final int activityId;
  final bool forceRefresh;

  const LoadVisitActivityDetails(this.activityId, {this.forceRefresh = false});

  @override
  List<Object?> get props => [activityId, forceRefresh];
}

class LoadVisitDetails extends VisitEvent {
  final int visitId;

  const LoadVisitDetails(this.visitId);

  @override
  List<Object?> get props => [visitId];
}

class ClearVisitFeedback extends VisitEvent {
  const ClearVisitFeedback();
}
