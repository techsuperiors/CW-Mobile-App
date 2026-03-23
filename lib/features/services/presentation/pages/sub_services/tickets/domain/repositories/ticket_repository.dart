import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../entities/ticket.dart';

/// Ticket Stats Entity
class TicketStats {
  final int open;
  final int inProgress;
  final int resolved;
  final int escalated;

  TicketStats({
    required this.open,
    required this.inProgress,
    required this.resolved,
    required this.escalated,
  });
}

/// Ticket repository interface
abstract class TicketRepository {
  Future<Either<Failure, TicketList>> getTicketList(String requestType);
  Future<Either<Failure, TicketStats>> getTicketStats();
  Future<Either<Failure, TicketDetails>> getTicketDetails(int ticketId);
  Future<Either<Failure, List<UploadedFile>>> uploadTicketFile(
    int clientId,
    int ticketId,
    String filePath,
  );
  Future<Either<Failure, String>> deleteTicketFile(
    int supportDocumentId,
    String fileId,
  );
}
