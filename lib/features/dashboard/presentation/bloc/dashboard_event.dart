import 'package:equatable/equatable.dart';

/// Dashboard events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load dashboard statistics
class LoadDashboardStats extends DashboardEvent {
  const LoadDashboardStats();
}

/// Event to refresh dashboard statistics
class RefreshDashboardStats extends DashboardEvent {
  const RefreshDashboardStats();
}

