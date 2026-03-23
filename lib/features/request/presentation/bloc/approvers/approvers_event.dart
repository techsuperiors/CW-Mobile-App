import 'package:equatable/equatable.dart';

abstract class ApproversEvent extends Equatable {
  const ApproversEvent();

  @override
  List<Object> get props => [];
}

class FetchApprovers extends ApproversEvent {
  final String endpoint;
  final Map<String, dynamic> payload;

  const FetchApprovers({required this.endpoint, required this.payload});

  @override
  List<Object> get props => [endpoint, payload];
}
