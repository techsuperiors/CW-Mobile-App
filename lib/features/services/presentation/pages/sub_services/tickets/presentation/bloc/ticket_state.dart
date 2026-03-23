import 'package:equatable/equatable.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/ticket_repository.dart';

/// Ticket states
abstract class TicketState extends Equatable {
  const TicketState();

  @override
  List<Object> get props => [];
}

/// Initial state
class TicketInitial extends TicketState {
  const TicketInitial();
}

/// Loading state
class TicketLoading extends TicketState {
  const TicketLoading();
}

/// Loaded state
class TicketLoaded extends TicketState {
  final TicketList ticketList;
  final String requestType;

  const TicketLoaded({required this.ticketList, required this.requestType});

  @override
  List<Object> get props => [ticketList, requestType];
}

/// Error state
class TicketError extends TicketState {
  final String message;

  const TicketError(this.message);

  @override
  List<Object> get props => [message];
}

/// Stats loading state
class TicketStatsLoading extends TicketState {
  const TicketStatsLoading();
}

/// Stats loaded state
class TicketStatsLoaded extends TicketState {
  final TicketStats stats;

  const TicketStatsLoaded({required this.stats});

  @override
  List<Object> get props => [stats];
}

/// Stats error state
class TicketStatsError extends TicketState {
  final String message;

  const TicketStatsError(this.message);

  @override
  List<Object> get props => [message];
}

/// Combined state with both ticket list and stats
class TicketDataLoaded extends TicketState {
  final TicketList ticketList;
  final String requestType;
  final TicketStats stats;

  const TicketDataLoaded({
    required this.ticketList,
    required this.requestType,
    required this.stats,
  });

  @override
  List<Object> get props => [ticketList, requestType, stats];
}

/// Ticket details loading state
class TicketDetailsLoading extends TicketState {
  const TicketDetailsLoading();
}

/// Ticket details loaded state
class TicketDetailsLoaded extends TicketState {
  final TicketDetails details;

  const TicketDetailsLoaded({required this.details});

  @override
  List<Object> get props => [details];
}

/// Ticket details error state
class TicketDetailsError extends TicketState {
  final String message;

  const TicketDetailsError(this.message);

  @override
  List<Object> get props => [message];
}

/// Ticket file upload loading state
class TicketFileUploading extends TicketState {
  const TicketFileUploading();
}

/// Ticket file upload success state
class TicketFileUploaded extends TicketState {
  final List<UploadedFile> uploadedFiles;

  const TicketFileUploaded({required this.uploadedFiles});

  @override
  List<Object> get props => [uploadedFiles];
}

/// Ticket file upload error state
class TicketFileUploadError extends TicketState {
  final String message;

  const TicketFileUploadError(this.message);

  @override
  List<Object> get props => [message];
}
