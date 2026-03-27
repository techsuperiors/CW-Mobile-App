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
  static const Object _unset = Object();
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
    Object? searchQuery = _unset,
    Object? statusFilter = _unset,
  }) {
    return RegularizeRequestLoaded(
      regularizeRequests: regularizeRequests ?? this.regularizeRequests,
      filteredRegularizeRequests: filteredRegularizeRequests ?? this.filteredRegularizeRequests,
      searchQuery:
      identical(searchQuery, _unset) ? this.searchQuery : searchQuery as String?,
      statusFilter:
      identical(statusFilter, _unset)
          ? this.statusFilter
          : statusFilter as RegularizeStatus?,
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
