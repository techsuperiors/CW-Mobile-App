import '../../domain/entities/ticket.dart';
import '../../domain/models/ticket_model.dart';

/// Mapper to convert Ticket entity to TicketModel
class TicketMapper {
  static TicketModel toTicketModel(Ticket ticket) {
    // Format date from ISO string to readable format
    String formatDate(String isoDate) {
      try {
        final date = DateTime.parse(isoDate);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return isoDate;
      }
    }

    // Get category name, fallback to empty string
    final category = ticket.subcategoryName ?? ticket.categoryName;

    return TicketModel(
      ticketId: ticket.id,
      id: ticket.ticketID,
      title: ticket.subject,
      fullTitle: ticket.subject,
      category: category,
      raisedDate: formatDate(ticket.createdAt),
      priority: ticket.priority,
      status: ticket.ticketStatus,
      description: null,
      raisedBy: ticket.createdByUser.fullName,
      raisedByAvatar: ticket.createdByUser.imageUrl,
      attachments: null,
    );
  }

  static List<TicketModel> toTicketModelList(List<Ticket> tickets) {
    return tickets.map((ticket) => toTicketModel(ticket)).toList();
  }
}
