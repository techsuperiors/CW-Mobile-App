import 'package:equatable/equatable.dart';

/// Ticket events
abstract class TicketEvent extends Equatable {
  const TicketEvent();

  @override
  List<Object> get props => [];
}

/// Load ticket list event
class LoadTicketList extends TicketEvent {
  final String requestType; // 'my_ticket' or 'assigned_ticket'

  const LoadTicketList(this.requestType);

  @override
  List<Object> get props => [requestType];
}

/// Refresh ticket list event
class RefreshTicketList extends TicketEvent {
  final String requestType; // 'my_ticket' or 'assigned_ticket'

  const RefreshTicketList(this.requestType);

  @override
  List<Object> get props => [requestType];
}

/// Load ticket stats event
class LoadTicketStats extends TicketEvent {
  const LoadTicketStats();
}

/// Load both ticket list and stats event
class LoadTicketData extends TicketEvent {
  final String requestType; // 'my_ticket' or 'assigned_ticket'

  const LoadTicketData(this.requestType);

  @override
  List<Object> get props => [requestType];
}

/// Load ticket details event
class LoadTicketDetails extends TicketEvent {
  final int ticketId;

  const LoadTicketDetails(this.ticketId);

  @override
  List<Object> get props => [ticketId];
}

/// Upload ticket file event
class UploadTicketFile extends TicketEvent {
  final int clientId;
  final int ticketId;
  final String filePath;

  const UploadTicketFile({
    required this.clientId,
    required this.ticketId,
    required this.filePath,
  });

  @override
  List<Object> get props => [clientId, ticketId, filePath];
}
