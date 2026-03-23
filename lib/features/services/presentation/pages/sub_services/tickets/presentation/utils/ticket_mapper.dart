import '../../domain/entities/ticket.dart';
import '../../domain/models/ticket_model.dart';

/// Mapper to convert Ticket entity to TicketModel
class TicketMapper {
  static TicketModel toTicketModel(Ticket ticket) {
    return TicketModel(
      ticketId: ticket.id,
      id: ticket.ticketID,
      title: ticket.subject.length > 30
          ? '${ticket.subject.substring(0, 30)}...'
          : ticket.subject,
      fullTitle: ticket.subject,
      category: ticket.categoryName,
      raisedDate: ticket.createdAt,
      priority: ticket.priority,
      status: ticket.ticketStatus,
      createdAt: DateTime.parse(ticket.createdAt), // ✅ Parse here
      raisedBy: ticket.createdByUser.fullName,
    );
  }
  // static List<TicketModel> toTicketModelList(List<Ticket> tickets)
  // {
  //   return tickets.map((ticket) => toTicketModel(ticket)).toList();
  // }
  static List<TicketModel> toTicketModelList(List<Ticket> tickets) {
    final list = tickets.map((e) => toTicketModel(e)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
