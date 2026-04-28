import 'package:equatable/equatable.dart';

abstract class EmployeeDirectoryEvent extends Equatable {
  const EmployeeDirectoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadEmployeeDirectory extends EmployeeDirectoryEvent {
  final bool forceRefresh;

  const LoadEmployeeDirectory({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadMoreEmployeeDirectory extends EmployeeDirectoryEvent {
  const LoadMoreEmployeeDirectory();
}

class LoadEmployeeDirectoryDetail extends EmployeeDirectoryEvent {
  final int userId;
  final bool forceRefresh;

  const LoadEmployeeDirectoryDetail({
    required this.userId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [userId, forceRefresh];
}

class ClearEmployeeDirectoryDetail extends EmployeeDirectoryEvent {
  const ClearEmployeeDirectoryDetail();
}
