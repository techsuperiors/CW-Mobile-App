import 'package:equatable/equatable.dart';

import '../models/regularize_request_model.dart';

/// Regularize request states
abstract class RegularizeRequestState extends Equatable {
  const RegularizeRequestState();

  @override
  List<Object> get props => [];
}

/// Initial state
class RegularizeRequestInitial extends RegularizeRequestState {
  const RegularizeRequestInitial();
}

/// Loading state
class RegularizeRequestLoading extends RegularizeRequestState {
  const RegularizeRequestLoading();
}

/// Loaded state
class RegularizeRequestLoaded extends RegularizeRequestState {
  final List<RegularizeRequestModel> regularizeRequests;
  final List<RegularizeRequestModel> filteredRegularizeRequests;
  final String? searchQuery;
  final RegularizeStatus? statusFilter;

  const RegularizeRequestLoaded({
    required this.regularizeRequests,
    required this.filteredRegularizeRequests,
    this.searchQuery,
    this.statusFilter,
  });

  @override
  List<Object> get props => [
        regularizeRequests,
        filteredRegularizeRequests,
        searchQuery ?? '',
        statusFilter ?? '',
      ];

  RegularizeRequestLoaded copyWith({
    List<RegularizeRequestModel>? regularizeRequests,
    List<RegularizeRequestModel>? filteredRegularizeRequests,
    String? searchQuery,
    RegularizeStatus? statusFilter,
  }) {
    return RegularizeRequestLoaded(
      regularizeRequests: regularizeRequests ?? this.regularizeRequests,
      filteredRegularizeRequests: filteredRegularizeRequests ?? this.filteredRegularizeRequests,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

/// Error state
class RegularizeRequestError extends RegularizeRequestState {
  final String message;

  const RegularizeRequestError(this.message);

  @override
  List<Object> get props => [message];
}
